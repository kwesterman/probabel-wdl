#...writing straight up code here...
#padir=ProbABEL/src
#gtdatadir=ProbABEL/examples/gtdata
#phenofile=ProbABEL/examples/height.txt
#dosefile=test.mldose
#infofile=test.mlinfo
#mapfile=test.map
#chrom=19
#outprefix=height_base
#${padir}/palinear \
#	-p $phenofile \
#	-d ${gtdatadir}/${dosefile} \
#	-i ${gtdatadir}/${infofile} \
#	-m ${gtdatadir}/${mapfile} \
#	-c $chrom \
#	-o ${outprefix}
#

task run_pa {
	File phenofile = ProbABEL/examples/height.txt
	File mydosefile = test.mldose
	File infofile = test.mlinfo
	File mapfile = test.map
	String chrom = 19
	String outprefix = height_base

	command {
		${padir}/palinear \
			-p $phenofile \
			-d ${gtdatadir}/${dosefile} \
			-i ${gtdatadir}/${infofile} \
			-m ${gtdatadir}/${mapfile} \
			-c $chrom \
			-o ${outprefix}
	}

	output {
		File out = ${outprefix}_add.out.txt
	}
}		

workflow {

	String pa_dir = ProbABEL/src
	String gtdata_dir = ProbABEL/examples/gtdata

	call run_pa {
		input: 
			phenofile = myphenofile,
			dosefile = mydosefile,
			infofile = myinfofile,
			mapfile = mymapfile,
			chrom = mychrom,
			outprefix = myoutprefix
	}			
	
	output {
		File outfile = run_pa.out
	}
}
