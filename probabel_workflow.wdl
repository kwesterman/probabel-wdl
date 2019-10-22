task sanitize_info {

	File infofile
	String infofile_base = basename(infofile)

	command <<<
		cat ${infofile} \
			| cut -f 1-7 \
			| awk 'gsub("-","1",$6); {print}' \
			| awk 'gsub("-","1",$7); {print}' \
			> "${infofile_base}.clean"
	>>>

	runtime {
		docker: "kwesterman/probabel-workflow:0.3"
		memory: "1 GB"
	}

	output {
		File sanitized = "${infofile_base}.clean"
	}
}

task run_interaction {
  
        File dosefile
        File infofile
        File? mapfile
        String chrom
        File phenofile
	Boolean binary_outcome
	Int? interaction
	Boolean? robust
	String? memory = 10
	String? disk = 20
	String mode = if binary_outcome then "palogist" else "palinear"

        command {
                /ProbABEL/src/${mode} \
                        -p ${phenofile} \
                        -d ${dosefile} \
                        -i ${infofile} \
                        ${"-m" + mapfile} \
			--interaction=${default=1 interaction} \
			${default="" true="--robust" false="" robust} \
                        -o probabel_res_${chrom}
        }

	runtime {
		docker: "kwesterman/probabel-workflow:0.3"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

        output {
                File res = "probabel_res_${chrom}_add.out.txt"
        }
}

task standardize_output {

	File resfile
	String exposure
	String outfile = "probabel_res_add.out.fmt.txt"

	command {
		python /probabel-workflow/format_probabel_output.py ${resfile} ${exposure} ${outfile}
	}

	runtime {
		docker: "kwesterman/probabel-workflow:0.3"
		memory: "1 GB"
	}

        output {
                File res_fmt = "${outfile}"
	}
}
			

workflow run_probabel {

	Array[File] dosefiles
	Array[File] infofiles
	File? mapfile
	Array[String] chroms
	File phenofile
	Boolean binary_outcome
	Int? interaction
	String exposure
	Boolean? robust
	String? memory
	String? disk

	parameter_meta {
		phenofile: "Comma-delimited phenotype file with subject IDs in the first column and the outcome of interest (quantitative or binary) in the second column"
		infofile: "Variant information file. NOTE: preprocessing step within this workflow will trim the info file to the first 7 columns and sanitize columns 6 & 7 (typically Quality and Rsq) by replacing dashes with a value of 1. Ideally, this input file contains only numeric values in columns 6 & 7."
		binary_outcome: "Boolean -- is the outcome binary? Otherwise, quantitative is assumed."
	}
	
	scatter (infofile in infofiles) {
		call sanitize_info {
			input: 
				infofile = infofile
		}
	}
	
	#Array[Pair[File,File]] filesets = zip(dosefiles, sanitize_info.sanitized)
	

	scatter (i in range(length(dosefiles))) {
		call run_interaction {
			input:
				dosefile = dosefiles[i],
				infofile = sanitize_info.sanitized[i],
				mapfile = mapfile,
				chrom = chroms[i],
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
}
