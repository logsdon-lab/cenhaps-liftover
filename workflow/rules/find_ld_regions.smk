

use rule wget as wget_chm13_tracks with:
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "{track}.bb"),
    params:
        url=lambda wc: (
            "https://hgdownload.soe.ucsc.edu/gbdb/hs1/censat/censat.bb"
            if wc.track == "censat"
            else "https://hgdownload.soe.ucsc.edu/gbdb/hs1/sedefSegDups/sedefSegDups.bb"
        ),
    log:
        "logs/wget_{track}_tracks.log",


rule convert_bbed_to_bed:
    input:
        rules.wget_chm13_tracks.output,
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "{track}.bed"),
    log:
        "logs/convert_bbed_to_bed_{track}.log",
    conda:
        "../envs/tools.yaml"
    shell:
        """
        bigBedToBed {input} {output} 2> {log}
        """


rule extract_genome_start_to_qarm_sizes:
    input:
        rules.flatten_coords.output,
    output:
        os.path.join(
            OUTPUT_DIR,
            "find_ld_regions",
            "{liftover}_pqarm_cenhap_coords_start_to_qarm_length.bed",
        ),
    shell:
        """
        awk -v OFS="\\t" '{{ print $1, $3}}' {input} > {output}
        """


rule filter_censat_regions:
    input:
        bed=expand(rules.convert_bbed_to_bed.output, track="censat"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "censat_filtered.bed"),
    params:
        allowed_censat_prefixes="|".join(ALLOWED_CENSAT_PREFIXES),
    shell:
        """
        grep -Pv "{params.allowed_censat_prefixes}" {input} | grep -v "chrY" | cut -f 1,2,3,4 > {output}
        """


rule filter_segdup_regions:
    input:
        bed=expand(rules.convert_bbed_to_bed.output, track="segdup"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "segdup_filtered.bed"),
    shell:
        """
        grep -Pv "chrM|chrY" {input} | cut -f 1,2,3,4 > {output}
        """


# TODO: Fix acros starting positions.
rule find_ld_regions:
    input:
        censat_bed=rules.filter_censat_regions.output,
        segdup_bed=rules.filter_segdup_regions.output,
        genome_sizes=expand(
            rules.extract_genome_start_to_qarm_sizes.output, liftover=["hg38-chm13"]
        ),
        ld_bed=expand(rules.flatten_coords.output, liftover=["hg38-chm13"]),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "ld_regions.bed"),
    params:
        allowed_censat_prefixes="".join(ALLOWED_CENSAT_PREFIXES),
    log:
        "logs/find_ld_regions.log",
    conda:
        "../envs/tools.yaml"
    shell:
        """
        {{ bedtools complement \
            -i <(cat {input.segdup_bed} {input.censat_bed} | sort -k 1,1 -k2,2n) \
            -g <(sort -k1,1 {input.genome_sizes}) | \
            bedtools intersect -a - -b {input.ld_bed} \
        ;}} > {output} 2> {log}
        """


rule annotate_filter_ld_regions:
    input:
        ld_bed=rules.find_ld_regions.output,
        censat_bed=expand(rules.convert_bbed_to_bed.output, track="censat"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "ld_regions_annotated.bed"),
    log:
        "logs/annotate_filter_ld_regions.log",
    params:
        len_threshold=4_000,
    conda:
        "../envs/tools.yaml"
    shell:
        """
        {{ bedtools intersect -wb -a {input.ld_bed} -b {input.censat_bed} | \
        awk -v OFS="\\t" '{{
            len=$3-$2
            if (len > {params.len_threshold}) {{
                print $1, $2, $3, $NF, len
            }} \
        }}' ;}}> {output} 2> {log}
        """


rule find_ld_regions_all:
    input:
        rules.annotate_filter_ld_regions.output,
