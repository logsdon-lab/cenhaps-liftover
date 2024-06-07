

use rule wget as wget_chm13_ref_asm with:
    output:
        outfile=os.path.join(OUTPUT_DIR, "extract_ld_regions_ref", "chm13v2.0.fa.gz"),
    params:
        url="https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz",
    log:
        "logs/get_chm13_ref_asm.log",


rule get_ld_regions_chm13:
    input:
        ref=rules.wget_chm13_ref_asm.output,
        bed=rules.merge_annotations_ld_regions.output,
    output:
        fa=temp(
            os.path.join(
                OUTPUT_DIR, "extract_ld_regions_ref", "chm13v2.0_ld_regions.fa"
            )
        ),
        faidx=temp(
            os.path.join(
                OUTPUT_DIR, "extract_ld_regions_ref", "chm13v2.0_ld_regions.fa.fai"
            )
        ),
    conda:
        "../envs/tools.yaml"
    log:
        "logs/get_ld_regions_chm13.log",
    shell:
        """
        seqtk subseq {input.ref} {input.bed} > {output.fa} 2> {log}
        samtools faidx {output.fa} 2>> {log}
        """


rule create_arm_info_name_key:
    input:
        fai=rules.get_ld_regions_chm13.output.faidx,
        bed=rules.merge_annotations_ld_regions.output,
    output:
        name_key=temp(
            os.path.join(
                OUTPUT_DIR, "extract_ld_regions_ref", "rename_fa_w_arm_key.tsv"
            )
        ),
    log:
        "logs/create_arm_info_name_key.log",
    shell:
        """
        {{ paste {input.fai} {input.bed} | awk -v OFS="\\t" '{{ print $1, $1"_"$9}}';}} > {output} 2> {log}
        """


rule add_arm_info_to_ld_regions_chm13:
    input:
        fa=rules.get_ld_regions_chm13.output.fa,
        name_key=rules.create_arm_info_name_key.output,
    output:
        fa=os.path.join(
            OUTPUT_DIR, "extract_ld_regions_ref", "chm13v2.0_ld_regions_w_arm.fa.gz"
        ),
        faidx=os.path.join(
            OUTPUT_DIR,
            "extract_ld_regions_ref",
            "chm13v2.0_ld_regions_w_arm.fa.gz.fai",
        ),
    conda:
        "../envs/tools.yaml"
    log:
        "logs/add_arm_info_to_ld_regions_chm13.log",
    shell:
        """
        {{ seqkit replace -p '^(\\S+)(.+?)$' -r '{{kv}}$2' -k {input.name_key} {input.fa} | bgzip ;}}> {output.fa} 2> {log}
        samtools faidx {output.fa} 2>> {log}
        """


rule extract_ld_regions_ref_all:
    input:
        rules.add_arm_info_to_ld_regions_chm13.output,
