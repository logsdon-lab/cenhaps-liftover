# `cenhaps-liftover`
Workflow to do the following:
1. Liftover hg19 cenhap coords to t2t-chm13.
2. Finds coordinates of centromere-proximal haplotypes:
    1. Only intersecting centromeric transition or monomeric alpha-satellite regions.
    2. Not within any segmental duplications.


### Usage
```bash
snakemake -p -c4 --use-conda
```

### Notes

**NOTE: chr 13, 14, 15, 21, and 22 p-arms are still unlifted.**

CenHap paper
* https://elifesciences.org/articles/42989

CenHap coords
* https://elifesciences.org/articles/42989/figures#fig2sdata1
* Raw file:
    * https://cdn.elifesciences.org/articles/42989/elife-42989-fig2-data1-v1.tds

Chain files
* hg19 -> hg38
    * https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz
* hg38 -> t2t-chm13
    * https://hgdownload.gi.ucsc.edu/hubs/GCA/009/914/755/GCA_009914755.4/liftOver/hg38-chm13v2.over.chain.gz
* hg19 -> t2t-chm13
    * Too many unliftable.
    * https://genome.ucsc.edu/cgi-bin/hgTrackUi?hgsid=1362452629_UneFYykJjrSS6NfDHXANksNtyvdb&db=hub_3267197_GCA_009914755.4&c=CP068276.2&g=hub_3267197_hgLiftOver


> [!NOTE]
> To see the previous output files, see commit [6875db8](https://github.com/koisland/cenhaps_liftover/tree/6875db8116bbea1a7c17c524ec18a46cc975e328)
