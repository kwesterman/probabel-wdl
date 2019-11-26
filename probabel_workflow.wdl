task process_phenos {
	
	File phenofile
	String sample_id_header
	String outcome
	String covar_headers
	String exposure
	String? delimiter = ","
	String? missing = "NA"

	command {
		python3 /format_probabel_phenos.py ${phenofile} ${sample_id_header} ${outcome} "${covar_headers}" ${exposure} "${delimiter}" ${missing}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "2*size(phenofile) GB"
	}

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
	String exposure
	String outfile_base = basename(resfile)
	String outfile = "${outfile_base}.fmt"

	command {
		python3 /format_probabel_output.py ${resfile} ${exposure} ${outfile}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "2*size(resfile) GB"
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
	String exposures
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
			exposure = exposures,
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
				phenofile = process_phenos.pheno_fmt,
				binary_outcome = binary_outcome,
				robust = robust,
				out_name = out_names[i],
				memory = memory,	
				disk = disk
		}
	}

	scatter (resfile in run_interaction.res) {
		call standardize_output {
			input:
				resfile = resfile,
				exposure = exposures
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
		exposures: "Column header name of the covariates to use as the exposure for genotype interaction testing (ProbABEL can only handle one). The exposure must also be provided as a covariate."
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
		description: "Run interaction tests using the ProbABEL package and return summary statistics for 1-DF and 2-DF tests."
	}
}
