task sanitize_info {

	File infofile
	String memory
	String infofile_base = basename(infofile)

	command <<<
		cat ${infofile} \
			| cut -f 1-7 \
			| awk 'gsub("-","1",$6); {print}' \
			| awk 'gsub("-","1",$7); {print}' \
			> "${infofile_base}.clean"
	>>>

	runtime {
		docker: "kwesterman/probabel-workflow:0.2"
		memory: "${memory} GB"
	}

	output {
		File sanitized = "${infofile_base}.clean"
	}
}

task run_interaction {
  
        File phenofile
        File dosefile
        File infofile
        File? mapfile
	Boolean binary_outcome
        String? chrom
	Int? interaction
	Boolean? robust
        String outprefix
	String memory
	String program = if binary_outcome then "palogist" else "palinear"

        command {
                /ProbABEL/src/${program} \
                        -p ${phenofile} \
                        -d ${dosefile} \
                        -i ${infofile} \
                        ${"-m" + mapfile} \
			${"-c" + chrom} \
			--interaction=${default=1 interaction} \
			${default="" true="--robust" false="" robust} \
                        -o ${outprefix}
        }

	runtime {
		docker: "kwesterman/probabel-workflow:0.2"
		memory: "${memory} GB"
	}

        output {
                File out = "${outprefix}_add.out.txt"
        }
}

workflow run_probabel {

	File phenofile
	Array[File] dosefiles
	File infofile
	File? mapfile
	Boolean binary_outcome
	String? chrom
	Int? interaction
	Boolean? robust
	String outprefix
	String memory

	parameter_meta {
		phenofile: "name: phenofile, label: phenotype_file, help: comma-delimited phenotype file with subject IDs in the first column and the outcome of interest (quantitative or binary) in the second column"
		infofile: "name: infofile, label: variant information file, help: NOTE: preprocessing step within this workflow will trim the info file to the first 7 columns and sanitize columns 6 & 7 (typically Quality and Rsq) by replacing dashes with a value of 1. Ideally, this input file contains only numeric values in columns 6 & 7."
		binary_outcome: "name: binary_outcome, label: binary outcome, help: Is the outcome binary? Otherwise, quantitative is assumed."
	}
	
	call sanitize_info {
		input: 
			infofile = infofile,
			memory = memory
	}

	scatter (dosefile in dosefiles) {
		call run_interaction {
			input:
				#pa_dir = pa_dir,
				#gtdata_dir = gtdata_dir,
				phenofile = phenofile,
				dosefile = dosefile,
				infofile = sanitize_info.sanitized,
				mapfile = mapfile,
				binary_outcome = binary_outcome,
				chrom = chrom,
				interaction = interaction,
				robust = robust,
				outprefix = outprefix,
				memory = memory
		}
	}

        #output {
        #        File outfile = run_interaction.out
        #}
}
