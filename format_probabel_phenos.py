import sys
import pandas as pd


phenofile, sample_id_header, outcome, exposure, covar_names, delimiter, missing, id_file = sys.argv[1:9]

phenos = pd.read_csv(phenofile, sep=delimiter, na_values=missing)

if id_file != "":  # Optional ID file ensures correct ordering of IDs
    ids = pd.read_csv(id_file, header=None, names=[sample_id_header])
    phenos = pd.merge(ids, phenos, how="left", on=sample_id_header)

covars = [] if covar_names == "" else covar_names.split(" ")
output_cols = [sample_id_header, outcome, exposure] + covars

phenos = phenos.loc[:, output_cols]

phenos.to_csv("probabel_phenotypes.csv", sep=" ", index=False, na_rep="NA")
