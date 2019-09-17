task run_pa {
  
        String pa_dir
        String gtdata_dir
        File phenofile
        File dosefile
        File infofile
        File mapfile
        String chrom
        String outprefix

        command {
                ${pa_dir}/palinear \
                        -p $phenofile \
                        -d ${gtdata_dir}/${dosefile} \
                        -i ${gtdata_dir}/${infofile} \
                        -m ${gtdata_dir}/${mapfile} \
                        -c $chrom \
                        -o ${outprefix}
        }

        output {
                File out = "${outprefix}_add.out.txt"
        }
}

workflow pa_wf {

        String pa_dir = "../ProbABEL/src"
        String gtdata_dir = "../ProbABEL/examples/gtdata"
        File phenofile = "../ProbABEL/examples/height.txt"
        File dosefile = "test.mldose"
        File infofile = "test.mlinfo"
        File mapfile = "test.map"
        String chrom = "19"
        String outprefix = "height_base"

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
