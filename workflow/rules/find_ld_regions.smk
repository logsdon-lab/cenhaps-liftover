

use rule wget as wget_chm13_tracks with:
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "{track}.bb"),
    params:
        url=lambda wc: TRACKS[str(wc.track)],
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
        echo "chrM\t1" >> {output}
        echo "chrY\t1" >> {output}
        awk -v OFS="\\t" '{{ print $1, $3}}' {input} >> {output}
        """


# These rules can be merged by track.
rule filter_censat_regions:
    input:
        bed=expand(rules.convert_bbed_to_bed.output, track="censat"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "censat_filtered.bed"),
    params:
        allowed_censat_prefixes="|".join(ALLOWED_CENSAT_PREFIXES),
    shell:
        """
        grep -Pv "{params.allowed_censat_prefixes}" {input} | cut -f 1,2,3,4 > {output}
        """


rule filter_segdup_regions:
    input:
        bed=expand(rules.convert_bbed_to_bed.output, track="segdup"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "segdup_filtered.bed"),
    shell:
        """
        cut -f 1,2,3,4 {input} > {output}
        """


# Repeatmasker annotations only take the first and last coordinate.
# We need all of them. Split on space in detailed annotation column.
rule filter_repeatmasker_regions:
    input:
        bed=expand(rules.convert_bbed_to_bed.output, track="repeatmasker"),
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "repeatmasker_filtered.bed"),
    params:
        allowed_region="ALR/Alpha",
    shell:
        """
        cut -f 14 {input} | sed 's/,/\\n/g' | awk -v OFS="\\t" '{{ if ($10 != "{params.allowed_region}") {{ print $5, $6, $7, $10"#"$11}}}}' > {output}
        """


rule find_ld_regions:
    """
    Find complement of segdup and censat regions, in other words, every other region between the start of the chr and the end of the q-arm.
    Then intersect with regions known to be in LD.
    """
    input:
        censat_bed=rules.filter_censat_regions.output,
        segdup_bed=rules.filter_segdup_regions.output,
        rm_bed=rules.filter_repeatmasker_regions.output,
        genome_sizes=expand(
            rules.extract_genome_start_to_qarm_sizes.output, liftover=["hg38-chm13"]
        ),
        ld_bed=expand(
            rules.liftover_coords.output.lifted_coords, liftover=["hg38-chm13"]
        ),
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
            -i <(cat {input.rm_bed} {input.segdup_bed} {input.censat_bed} | sort -k 1,1 -k2,2n) \
            -g <(sort -k1,1 {input.genome_sizes}) | \
            bedtools intersect -wa -wb -a - -b {input.ld_bed} \
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
    conda:
        "../envs/tools.yaml"
    shell:
        """
        {{ bedtools intersect -wa -wb -a {input.ld_bed} -b {input.censat_bed} | \
        awk -v OFS="\\t" '{{
            len=$3-$2
            print $1, $2, $3, $NF, $7, len
        }}' ;}}> {output} 2> {log}
        """


rule merge_annotations_ld_regions:
    """
    Intersection produces multiple identical rows with the censat annotation being different.
    This merges the annotation into one row in no particular order.
    """
    input:
        script="workflow/scripts/merge_ld_annot.py",
        regions=rules.annotate_filter_ld_regions.output,
    output:
        os.path.join(OUTPUT_DIR, "find_ld_regions", "ld_regions_annotated_merged.bed"),
    log:
        "logs/merge_annotations_ld_regions.log",
    conda:
        "../envs/py.yaml"
    shell:
        """
        python {input.script} {input.regions} > {output} 2> {log}
        """


rule find_ld_regions_all:
    input:
        rules.merge_annotations_ld_regions.output,
