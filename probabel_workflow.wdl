task sanitize_info {

	File infofile
	String infofile_base = basename(infofile)

	command <<<
		cat ${infofile} \
			| cut -f 1-7 \
			| awk 'gsub("-","1",$6)' \
			| awk 'gsub("-","1",$7); {print}' \
			> "${infofile_base}.clean"
	>>>

	runtime {
		docker: "kwesterman/probabel-workflow:0.4"
		memory: "1 GB"
	}

	output {
		File sanitized = "${infofile_base}.clean"
	}
}

task run_interaction {
  
        File genofile
        File infofile
        File? mapfile
        File phenofile
	Boolean binary_outcome
	Int? interaction
	Boolean? robust
        String out_name
	String? memory = 10
	String? disk = 20
	String mode = if binary_outcome then "palogist" else "palinear"

        command {
                /ProbABEL/src/${mode} \
                        -p ${phenofile} \
                        -d ${genofile} \
                        -i ${infofile} \
                        ${"-m" + mapfile} \
			--interaction=${default=1 interaction} \
			${default="" true="--robust" false="" robust} \
                        -o probabel_res_${out_name}
        }

	runtime {
		docker: "kwesterman/probabel-workflow:0.4"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

        output {
                File res = "probabel_res_${out_name}_add.out.txt"
        }
}

task standardize_output {

	File resfile
	String exposure
	String outfile_base = basename(resfile)
	String outfile = "${outfile_base}.fmt"

	command {
		python3 /probabel-workflow/format_probabel_output.py ${resfile} ${exposure} ${outfile}
	}

	runtime {
		docker: "kwesterman/probabel-workflow:0.4"
		memory: "1 GB"
	}

        output {
                File res_fmt = "${outfile}"
	}
}
			

workflow run_probabel {

	Array[File] genofiles
	Array[File] infofiles
	File? mapfile
	File phenofile
	Boolean binary_outcome
	Int? interaction
	String exposure
	Boolean? robust
	Array[String] out_names
	String? memory
	String? disk

	scatter (infofile in infofiles) {
		call sanitize_info {
			input: 
				infofile = infofile
		}
	}
	
	scatter (i in range(length(genofiles))) {
		call run_interaction {
			input:
				genofile = genofiles[i],
				infofile = sanitize_info.sanitized[i],
				mapfile = mapfile,
				out_name = out_names[i],
				phenofile = phenofile,
				binary_outcome = binary_outcome,
				interaction = interaction,
				robust = robust,
				memory = memory,	
				disk = disk
		}
	}

	scatter (resfile in run_interaction.res) {
		call standardize_output {
			input:
				resfile = resfile,
				exposure = exposure
		}
	}
	
	parameter_meta {
		genofiles: "Imputed genotypes in Minimac dosage format"
		infofiles: "Variant information files. NOTE: preprocessing step within this workflow will trim the info file to the first 7 columns and sanitize columns 6 & 7 (typically Quality and Rsq) by replacing dashes with a value of 1. Ideally, this input file contains only numeric values in columns 6 & 7."
		phenofile: "Comma-delimited phenotype file with subject IDs in the first column and the outcome of interest (quantitative or binary) in the second column"
		binary_outcome: "Boolean: is the outcome binary? Otherwise, quantitative is assumed."
		interaction: "Boolean: should an interaction term be included? The first covariate in the phenotype file will be used. Defaults to true."
		exposure: "Name of the interaction exposure to be used. NOTE: this does NOT affect the model, only the naming/post-processing."
		robust: "Boolean: should robust/sandwich/Huber-White standard errors be used?"
		out_names: "Names to be included for distinguishing output files."
		memory: "Memory required for the modeling step (in GB)."
		disk: "Disk space required for the modeling step (in GB)."
	}

	meta {
		author: "Kenny Westerman"
		email: "kewesterman@mgh.harvard.edu"
		description: "Run interaction tests using the ProbABEL package and return a table of summary statistics for 1-DF and 2-DF tests."
	}
}
