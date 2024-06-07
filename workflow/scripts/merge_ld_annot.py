import sys
import polars as pl


def main():
    args = sys.argv
    infile = args[1]
    # chr1	118628877	118788846	ct_1_1(p_arm)	p-arm	159969
    (
        pl.read_csv(
            infile,
            separator="\t",
            new_columns=["chr", "start", "stop", "censat", "arm", "len"],
            has_header=False,
        )
        .group_by(["chr", "start", "stop", "arm", "len"])
        .agg(censat=pl.col("censat").str.concat("|"))
        .sort(by=["chr", "start"])
        .write_csv(sys.stdout, include_header=False, separator="\t")
    )


if __name__ == "__main__":
    raise SystemExit(main())
