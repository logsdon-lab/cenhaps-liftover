#!/bin/bash

set -euo pipefail

wget -O - https://cdn.elifesciences.org/articles/42989/elife-42989-fig2-data1-v1.tds | \
awk -v FS="\t" \
    -v OFS="\t" \
    'NR > 3 \
    {
        if ($2 != "NA" || $3 != "NA" ) {
            print $1, $2, $3, "p-arm" > "hg19_parm_cenhap_coords.bed"
        }
        if ($4 != "NA" || $5 != "NA" ) {
            print $1, $4, $5, "q-arm" > "hg19_qarm_cenhap_coords.bed"
        } 
    }'

rm -f hg19ToHg38.over.chain.gz hg38-chm13v2.over.chain.gz
wget https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz
wget https://hgdownload.gi.ucsc.edu/hubs/GCA/009/914/755/GCA_009914755.4/liftOver/hg38-chm13v2.over.chain.gz

# hg19 -> hg38
./liftOver \
    hg19_parm_cenhap_coords.bed \
    hg19ToHg38.over.chain.gz \
    hg38_parm_cenhap_coords.bed \
    hg19ToHg38_parm_cenhaps_unlifted.bed

./liftOver \
    hg19_qarm_cenhap_coords.bed \
    hg19ToHg38.over.chain.gz \
    hg38_qarm_cenhap_coords.bed \
    hg19ToHg38_qarm_cenhaps_unlifted.bed

# hg38 -> t2t
./liftOver \
    hg38_parm_cenhap_coords.bed \
    hg38-chm13v2.over.chain.gz \
    chm13v2_parm_cenhap_coords.bed \
    hg38-chm13v2_parm_cenhaps_unlifted.bed

./liftOver \
    hg38_qarm_cenhap_coords.bed \
    hg38-chm13v2.over.chain.gz \
    chm13v2_qarm_cenhap_coords.bed \
    hg38-chm13v2_qarm_cenhaps_unlifted.bed