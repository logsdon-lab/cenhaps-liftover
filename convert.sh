#!/bin/bash

set -euo pipefail

wget -O - https://cdn.elifesciences.org/articles/42989/elife-42989-fig2-data1-v1.tds | \
awk -v FS="\t" \
    -v OFS="\t" \
    'NR > 3 {
        $2=($2 == "NA") ? 0 : $2;
        $5=($5 == "NA") ? 0 : $5;
        print $1, $2, $2+5000, "p-arm"; 
        print $1, $5-5000, $5, "q-arm";
    }'> hg19_pqarm_cenhap_coords.bed

rm -f hg19ToHg38.over.chain.gz hg38-chm13v2.over.chain.gz
wget https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz
wget https://hgdownload.gi.ucsc.edu/hubs/GCA/009/914/755/GCA_009914755.4/liftOver/hg38-chm13v2.over.chain.gz

# hg19 -> hg38
./liftOver \
    hg19_pqarm_cenhap_coords.bed \
    hg19ToHg38.over.chain.gz \
    hg38_pqarm_cenhap_coords.bed \
    hg19ToHg38_pqarm_cenhaps_unlifted.bed

# hg38 -> t2t
./liftOver \
    hg38_pqarm_cenhap_coords.bed \
    hg38-chm13v2.over.chain.gz \
    chm13v2_pqarm_cenhap_coords.bed \
    hg38-chm13v2_pqarm_cenhaps_unlifted.bed

python3 bedminmax.py -i chm13v2_pqarm_cenhap_coords.bed > chm13v2_pqarm_cenhap_coords_collapsed.bed
