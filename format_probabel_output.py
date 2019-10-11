import pandas as pd
import sys


resfile, exposure = sys.argv[1:3]

names_dict = {'name': 'SNPID', 'A1': 'Allele1', 'A2': 'Allele2', 
	      'beta_SNP_addA1': 'Beta_Main', 'sebeta_SNP_addA1': 'SE_Beta_Main', 
	      'beta_SNP_' + exposure: 'Beta_Interaction_1', 
	      'sebeta_SNP_' + exposure: 'Var_Beta_Interaction_1_1'}

res = pd.read_csv(resfile, sep=" ")
res = res.rename(columns=names_dict)
res = res[list(names_dict.values())]
res.to_csv(resfile + ".fmt", index=False, na_rep="NaN")
