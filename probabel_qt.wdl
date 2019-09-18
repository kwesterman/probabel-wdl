task run_pa {
  
        String pa_dir
        String gtdata_dir
        String phenofile
        String dosefile
        String infofile
        String mapfile
        String chrom
        String outprefix

        command {
                ${pa_dir}/palinear \
                        -p ${phenofile} \
                        -d ${gtdata_dir}/${dosefile} \
                        -i ${gtdata_dir}/${infofile} \
                        -m ${gtdata_dir}/${mapfile} \
                        -c ${chrom} \
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

	String pa_dir = "/ProbABEL/src"
	String gtdata_dir = "/ProbABEL/examples/gtdata"
	String phenofile = "/ProbABEL/examples/height.txt"
	String dosefile
	String infofile
	String mapfile
	String chrom
	String outprefix

        call run_pa {
                input:
                        pa_dir = pa_dir,
                        gtdata_dir = gtdata_dir,
                        phenofile = phenofile,
                        dosefile = dosefile,
                        infofile = infofile,
                        mapfile = mapfile,
                        chrom = chrom,
                        outprefix = outprefix
        }

        output {
                File outfile = run_pa.out
        }
}
