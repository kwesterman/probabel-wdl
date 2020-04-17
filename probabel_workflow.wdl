task process_phenos {
	
	File phenofile
	String sample_id_header
	String outcome
	String exposure
	String covar_names
	String? delimiter = ","
	String? missing = "NA"

	command {
		python3 /format_probabel_phenos.py ${phenofile} ${sample_id_header} ${outcome} ${exposure} "${covar_names}" "${delimiter}" ${missing}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "2 GB"
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
			| awk '{ gsub("-","1",$6); print }' \
			| awk '{ gsub("-","1",$7); print }' \
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
	Boolean? robust = true
	Int? memory = 10
	Int? disk = 20
	String mode = if binary_outcome then "palogist" else "palinear"

        command {
		#dstat -c -d -m --nocolor 10 1>>resource_usage.log &
		echo "" > resource_usage.log
		atop -x -P PRC,PRM,PRD | grep '(GEM)' 1>>resource_usage.log &

                /ProbABEL/src/${mode} \
                        -p ${phenofile} \
                        -d ${genofile} \
                        -i ${infofile} \
			--interaction 1 \
			${default="" true="--robust" false="" robust} \
                        -o probabel_res
        }

	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

        output {
                File res = "probabel_res_add.out.txt"
		File resource_usage = "resource_usage.log"
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
		memory: "2 GB"
	}

        output {
                File res_fmt = "${outfile}"
	}
}

task cat_results {

	Array[File] results_array

	command {
		head -1 ${results_array[0]} > all_results.txt && \
			for res in ${sep=" " results_array}; do tail -n +2 $res >> all_results.txt; done
	}
	
	runtime {
		docker: "quay.io/large-scale-gxe-methods/probabel-workflow"
		disks: "local-disk 5 HDD"
	}

	output {
		File all_results = "all_results.txt"
	}
}
			

workflow run_probabel {

	Array[File] genofiles
	Array[File] infofiles
	File phenofile
	String sample_id_header
	String outcome
	Boolean binary_outcome
	String exposure_names
	String? covar_names = ""
	String? delimiter
	String? missing
	Boolean? robust
	Int? memory
	Int? disk

	call process_phenos {
		input:
			phenofile = phenofile,
			sample_id_header = sample_id_header,
			outcome = outcome,
			exposure = exposure_names,
			covar_names = covar_names,
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
				memory = memory,	
				disk = disk
		}
	}

	scatter (resfile in run_interaction.res) {
		call standardize_output {
			input:
				resfile = resfile,
				exposure = exposure_names
		}
	}	

	call cat_results {
		input:
			results_array = standardize_output.res_fmt
	}

        output {
                File results = cat_results.all_results
		Array[File] resource_usage = run_interaction.resource_usage
	}

	parameter_meta {
		genofiles: "Array of genotype filepaths in Minimac dosage format."
		infofiles: "Variant information files. NOTE: preprocessing step within this workflow will trim the info file to the first 7 columns and sanitize columns 6 & 7 (typically Quality and Rsq) by replacing dashes with a value of 1. Ideally, this input file contains only numeric values in columns 6 & 7."
		phenofile: "Phenotype filepath."	
		sample_id_header: "Column header name of sample ID in phenotype file."
		outcome: "Column header name of phenotype data in phenotype file."
		binary_outcome: "Boolean: is the outcome binary? Otherwise, quantitative is assumed."
		exposure_names: "Column header name(s) of the exposures for genotype interaction testing (space-delimited). Only one exposures is currently allowed."
		covar_names: "Column header name(s) of any covariates for which only main effects should be included (space-delimited). This set should not overlap with exposure_names."
		delimiter: "Delimiter used in the phenotype file."
		missing: "Missing value key of phenotype file."
		robust: "Boolean: should robust (a.k.a. sandwich/Huber-White) standard errors be used?"
		memory: "Requested memory for the interaction testing step (in GB)."
		disk: "Requested disk space for the interaction testing step (in GB)."
	}

	meta {
		author: "Kenny Westerman"
		email: "kewesterman@mgh.harvard.edu"
		description: "Run interaction tests using the ProbABEL package and return summary statistics for 1-DF and 2-DF tests."
	}
}
