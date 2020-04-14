import sys
import pandas as pd


phenofile, sample_id_header, outcome, exposure, covar_names, delimiter, missing = sys.argv[1:8]

covars = [] if covar_names == "" else covar_names.split(" ")
output_cols = [sample_id_header, outcome, exposure] + covars

phenos = (pd.read_csv(phenofile, sep=delimiter, na_values=missing)
          .loc[:, output_cols])
phenos.to_csv("probabel_phenotypes.csv", sep=" ", index=False, na_rep="NA")
