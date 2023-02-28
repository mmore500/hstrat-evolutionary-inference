import sys
import math
import ALifeStdDev.phylogeny as phylodev

if len(sys.argv) < 5:
    print("Usage: python consolidate_phylogeny.py [phylogeny_file] [output_file_name] [maximum_trait_value] [resolution]")

filename = sys.argv[1]
outfile = sys.argv[2]
max_trait_val = int(sys.argv[3])
resolution = int(sys.argv[4])
df = phylodev.load_phylogeny_to_pandas_df(filename)

min_val = 0
max_val = max_trait_val
num_bins = resolution
bin_width = (max_val - min_val)/num_bins

df["Bin"] = df["trait"].apply(lambda x: math.floor((num_bins - 1) * (x - min_val)/max_val))

g = phylodev.pandas_df_to_networkx(df)

abstract_g = phylodev.abstract_asexual_phylogeny(g, ["Bin"])
final_df = phylodev.networkx_to_pandas_df(abstract_g, {"trait":"Bin", "origin_time":"origin_time"})
final_df.to_csv(outfile, index=False)