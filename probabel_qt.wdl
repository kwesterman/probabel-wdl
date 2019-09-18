task run_pa {
  
        #String pa_dir
        #String gtdata_dir
        File phenofile
        File dosefile
        File infofile
        File mapfile
        String chrom
	Int? interaction
	Boolean? robust
        String outprefix

        command {
                /ProbABEL/src/palinear \
                        -p ${phenofile} \
                        -d ${dosefile} \
                        -i ${infofile} \
                        -m ${mapfile} \
                        -c ${chrom} \
			--interaction=${default=1 interaction} \
			${default="" true="--robust" false="" robust} \
                        -o ${outprefix}
        }

	runtime {
		docker: "kwesterman/probabel-workflow:0.2"
	}

        output {
                File out = "${outprefix}_add.out.txt"
        }
}

workflow pa_wf {

	#String pa_dir = "/ProbABEL/src"
	#String gtdata_dir = "/ProbABEL/examples/gtdata"
	File phenofile
	File dosefile
	File infofile
	File mapfile
	String chrom
	Int? interaction
	Boolean? robust
	String outprefix

        call run_pa {
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
                        outprefix = outprefix
        }

        output {
                File outfile = run_pa.out
        }
}
