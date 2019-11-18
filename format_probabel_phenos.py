import sys
import pandas as pd


phenofile, sample_id_header, outcome, covar_headers, int_covar_num, delimiter, missing = sys.argv[1:8]

covars = covar_headers.split(" ")
exposure = covars.pop(int(int_covar_num) - 1)
output_cols = [sample_id_header, outcome, exposure] + covars

phenos = (pd.read_csv(phenofile, sep=delimiter, na_values=missing)
          .loc[:, output_cols])
phenos.to_csv("probabel_phenotypes.csv", sep=" ", index=False, na_rep="NA")
