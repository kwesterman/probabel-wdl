task process_phenos {
	
	File phenofile
	String sample_id_header
	String outcome
	String covar_headers
	String int_covar_num
	String? delimiter = ","
	String? missing = "NA"

	# String phenofile_size = size(phenofile)

	command {
		python3 /format_probabel_phenos.py ${phenofile} ${sample_id_header} ${outcome} "${covar_headers}" ${int_covar_num} "${delimiter}" ${missing}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "1 GB"
	}
		#memory: "2*${phenofile_size} GB"

        output {
                File pheno_fmt = "probabel_phenotypes.csv"
	}
}

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
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "1 GB"
	}

	output {
		File sanitized = "${infofile_base}.clean"
	}
}

task run_interaction {
  
        File genofile
        File infofile
        File phenofile
	Boolean binary_outcome
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
			--interaction 1 \
			${default="" true="--robust" false="" robust} \
                        -o probabel_res_${out_name}
        }

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

        output {
                File res = "probabel_res_${out_name}_add.out.txt"
        }
}

task standardize_output {

	File resfile
	String covar_headers
	String int_covar_num
	String outfile_base = basename(resfile)
	String outfile = "${outfile_base}.fmt"

	command {
		python3 /format_probabel_output.py ${resfile} "${covar_headers}" ${int_covar_num} ${outfile}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "1 GB"
	}

        output {
                File res_fmt = "${outfile}"
	}
}
			

workflow run_probabel {

	Array[File] genofiles
	Array[File] infofiles
	File phenofile
	String sample_id_header
	String outcome
	Boolean binary_outcome
	String covar_headers
	String int_covar_num
	String? delimiter
	String? missing
	Boolean? robust
	Array[String] out_names
	String? memory
	String? disk

	call process_phenos {
		input:
			phenofile = phenofile,
			sample_id_header = sample_id_header,
			outcome = outcome,
			covar_headers = covar_headers,
			int_covar_num = int_covar_num,
			delimiter = delimiter,
			missing = missing
	}

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
				out_name = out_names[i],
				phenofile = process_phenos.pheno_fmt,
				binary_outcome = binary_outcome,
				robust = robust,

				memory = memory,	
				disk = disk
		}
	}

	scatter (resfile in run_interaction.res) {
		call standardize_output {
			input:
				resfile = resfile,
				covar_headers = covar_headers,
				int_covar_num = int_covar_num
		}
	}	

	parameter_meta {
		genofiles: "Array of genotype filepaths in Minimac dosage format."
		infofiles: "Variant information files. NOTE: preprocessing step within this workflow will trim the info file to the first 7 columns and sanitize columns 6 & 7 (typically Quality and Rsq) by replacing dashes with a value of 1. Ideally, this input file contains only numeric values in columns 6 & 7."
		phenofile: "Phenotype filepath."	
		sample_id_header: "Column header name of sample ID in phenotype file."
		outcome: "Column header name of phenotype data in phenotype file."
		binary_outcome: "Boolean: is the outcome binary? Otherwise, quantitative is assumed."
		covar_headers: "Column header names of the selected covariates in the pheno data file."
		int_covar_num: "Indexes of the covariates for which interactions with genotype should be included ('1' means use the first covariate, '2 3' means use the second and third covariates, etc.)."
		delimiter: "Delimiter used in the phenotype file."
		missing: "Missing value key of phenotype file."
                robust: "Boolean: should robust (a.k.a. sandwich/Huber-White) standard errors be used?"
        missing: "Missing value key of phenotype file."
		out_names: "Array of names to distinguish output files (e.g. chromosome numbers)."
		memory: "Requested memory for the interaction testing step (in GB)."
		disk: "Requested disk space for the interaction testing step (in GB)."
	}

	meta {
		author: "Kenny Westerman"
		email: "kewesterman@mgh.harvard.edu"
		description: "Run interaction tests using the ProbABEL package and return a table of summary statistics for 1-DF and 2-DF tests."
	}
}
