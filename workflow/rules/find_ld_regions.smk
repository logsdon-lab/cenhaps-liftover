

use rule wget as wget_chm13_tracks with:
    output:
        os.path.join(OUTPUT_DIR, "{track}.bb"),
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
        os.path.join(OUTPUT_DIR, "{track}.bed"),
    log:
        "logs/convert_bbed_to_bed_{track}.log",
    conda:
        "../envs/tools.yaml"
    shell:
        """
        bigBedToBed {input} {output} 2> {log}
        """


rule extract_start_to_qarm:
    input:
        os.path.join(OUTPUT_DIR, "hg38-chm13_pqarm_cenhap_coords_collapsed.bed"),
    output:
        os.path.join(
            OUTPUT_DIR, "hg38-chm13_pqarm_cenhap_coords_start_to_qarm_length.bed"
        ),
    shell:
        """
        awk -v OFS="\\t" '{{ print $1, $3}}'
        """


# rule filter_censat:
#     input:
#         ""
#     output:
#         ""
#     params:
#         allowed_censat_prefixes="".join(ALLOWED_CENSAT_PREFIXES)
#     shell:
#         """
#         """


rule find_ld_regions_all:
    input:
        expand(rules.convert_bbed_to_bed.output, track=TRACKS),
