task run_interaction {
  
        File phenofile
        File dosefile
        File infofile
        File mapfile
        String? chrom
	Int? interaction
	Boolean? robust
        String outprefix
	String memory

        command {
                /ProbABEL/src/palinear \
                        -p ${phenofile} \
                        -d ${dosefile} \
                        -i ${infofile} \
                        -m ${mapfile} \
                        -c ${default="" chrom} \
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
	File mapfile
	String? chrom
	Int? interaction
	Boolean? robust
	String outprefix
	String memory

	scatter (dosefile in dosefiles) {
		call run_interaction {
			input:
				#pa_dir = pa_dir,
				#gtdata_dir = gtdata_dir,
				phenofile = phenofile,
				dosefile = dosefile,
				infofile = infofile,
				mapfile = mapfile,
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
