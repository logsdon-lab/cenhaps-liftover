
import sys
import pandas as pd
import argparse

parser = argparse.ArgumentParser(description="")

parser.add_argument(
    "-i", "--bed", help="input 4 column bed file", type=str, required=True
)
parser.add_argument(
    "-o",
    "--output",
    help="output file default /dev/stdout",
    type=argparse.FileType("wt"),
    default=sys.stdout,
    required=False,
)

args = parser.parse_args()

bed_df = pd.read_csv(args.bed, sep="\t", header=None, usecols=[0, 1, 2, 3])

bed_df.rename(
    {0: "chr", 1: "start", 2: "end", 3: "name", 4: "arm"}, axis=1, inplace=True
)

bed_out = pd.merge(
    bed_df.groupby(["chr"]).min()["start"],
    bed_df.groupby(["chr"]).max()["end"],
    left_index=True,
    right_index=True,
).reset_index()

bed_out[["chr", "start", "end"]].sort_values(
    by=["chr", "start"]
).to_csv(args.output, sep="\t", header=False, index=False)