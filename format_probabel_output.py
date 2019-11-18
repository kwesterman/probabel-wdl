import sys
import pandas as pd
from scipy.stats import chi2


resfile, covar_headers, int_covar_num, outfile = sys.argv[1:5]

exposure = covar_headers.split(" ")[int(int_covar_num) - 1]

names_dict = {'name': 'SNPID', 'A1': 'Allele1', 'A2': 'Allele2', 
	      'beta_SNP_addA1': 'Beta_Main', 'sebeta_SNP_addA1': 'SE_Beta_Main', 
	      'beta_SNP_' + exposure: 'Beta_Interaction_1', 
	      'sebeta_SNP_' + exposure: 'SE_Beta_Interaction_1_1'}

res = (pd.read_csv(resfile, sep=" ")
       .rename(columns=names_dict)
       .filter(list(names_dict.values()))
       .assign(Var_Beta_Main = lambda x: x.SE_Beta_Main ** 2,
	       Var_Beta_Interaction_1_1 = lambda x: x.SE_Beta_Interaction_1_1 ** 2)
       .assign(P_Value_Main = lambda x: 1 - chi2.cdf(x.Beta_Main ** 2 / x.Var_Beta_Main, df=1),
	       P_Value_Interaction = lambda x: 1 - chi2.cdf(x.Beta_Interaction_1 ** 2 / x.Var_Beta_Interaction_1_1, df=1),
	       P_Value_Joint = lambda x: 1 - chi2.cdf(x.Beta_Main ** 2 / x.Var_Beta_Main + x.Beta_Interaction_1 ** 2 / x.Var_Beta_Interaction_1_1, df=2))
       .drop(["SE_Beta_Main", "SE_Beta_Interaction_1_1"], axis="columns"))
res.to_csv(outfile, sep=" ", index=False, na_rep="NaN")
