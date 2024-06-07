

rule get_hg19_pqarm_cenhap_coords:
    """
    Get hg19 pqarm cenhap coords.
    We add 5000 bp on both sides to help create anchor points on edges of the centromere for the liftover in the next step.
    """
    output:
        os.path.join(OUTPUT_DIR, "liftover_ld_regions", "hg19_pqarm_cenhap_coords.bed"),
    params:
        url_data="https://cdn.elifesciences.org/articles/42989/elife-42989-fig2-data1-v1.tds",
        bp_added=5000,
    log:
        "logs/get_hg19_pqarm_cenhap_coords.log",
    shell:
        """
        wget -O - {params.url_data} | \
        awk -v FS="\\t" -v OFS="\\t" \
            'NR > 3 {{
                $2=($2 == "NA") ? 0 : $2;
                $5=($5 == "NA") ? 0 : $5;
                print $1, $2, $2+{params.bp_added}, "p-arm";
                print $1, $5-{params.bp_added}, $5, "q-arm";
            }}' > {output}
        """


use rule wget as wget_chain_file with:
    output:
        outfile=os.path.join(
            OUTPUT_DIR, "liftover_ld_regions", "{liftover}.over.chain.gz"
        ),
    params:
        url=lambda wc: (
            "https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz"
            if wc.liftover == "hg19-hg38"
            else "https://hgdownload.gi.ucsc.edu/hubs/GCA/009/914/755/GCA_009914755.4/liftOver/hg38-chm13v2.over.chain.gz"
        ),
    log:
        "logs/get_chain_file_{liftover}.log",


rule liftover_coords:
    input:
        coords=lambda wc: (
            rules.get_hg19_pqarm_cenhap_coords.output
            if wc.liftover == "hg19-hg38"
            else expand(
                rules.liftover_coords.output.lifted_coords, liftover=["hg19-hg38"]
            )
        ),
        chain_file=rules.wget_chain_file.output,
    output:
        lifted_coords=os.path.join(
            OUTPUT_DIR, "liftover_ld_regions", "{liftover}_pqarm_cenhap_coords.bed"
        ),
        unlifted_coords=os.path.join(
            OUTPUT_DIR,
            "liftover_ld_regions",
            "{liftover}_pqarm_cenhap_coords_unlifted.bed",
        ),
    log:
        "logs/liftover_{liftover}.log",
    conda:
        "../envs/tools.yaml"
    shell:
        """
        liftOver \
            {input.coords} \
            {input.chain_file} \
            {output.lifted_coords} \
            {output.unlifted_coords} 2> {log}
        """


rule flatten_coords:
    input:
        script="workflow/scripts/bedminmax.py",
        coords=rules.liftover_coords.output.lifted_coords,
    output:
        os.path.join(
            OUTPUT_DIR,
            "liftover_ld_regions",
            "{liftover}_pqarm_cenhap_coords_collapsed.bed",
        ),
    log:
        "logs/flatten_coords_{liftover}.log",
    params:
        in_cols=" ".join(["chr", "start", "end", "arm"]),
        out_cols=" ".join(["chr", "start", "end"]),
        grp_cols=" ".join(["chr"]),
    conda:
        "../envs/py.yaml"
    shell:
        """
        python3 {input.script} bedminmax \
        -i {input.coords} \
        -ci {params.in_cols} \
        -co {params.out_cols} \
        -g {params.grp_cols} > {output} 2> {log}
        """


rule liftover_all:
    input:
        expand(rules.flatten_coords.output, liftover=LIFTOVERS),
    default_target: True
