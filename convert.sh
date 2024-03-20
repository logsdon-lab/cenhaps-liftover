#!/bin/bash

set -euo pipefail

awk -v FS="\t" \
    -v OFS="\t" \
    'NR > 1 \
    {
        if ($2 != "NA" || $3 != "NA" ) {
            print $1, $2, $3, "p-arm"
        }
    }' elife-42989-fig2-data1-v1.tds > hg19_parm_cenhap_coords.bed

awk -v FS="\t" \
    -v OFS="\t" \
    'NR > 1 \
    {
        if ($4 != "NA" || $5 != "NA" ) {
            print $1, $4, $5, "q-arm"
        }
    }' elife-42989-fig2-data1-v1.tds > hg19_qarm_cenhap_coords.bed

./liftOver \
    hg19_parm_cenhap_coords.bed \
    hg19-chm13v2.over.chain.gz \
    chm13v2_parm_cenhap_coords.bed \
    parm_cenhaps_unlifted.bed

./liftOver \
    hg19_qarm_cenhap_coords.bed \
    hg19-chm13v2.over.chain.gz \
    chm13v2_qarm_cenhap_coords.bed \
    qarm_cenhaps_unlifted.bed