#!/bin/bash
# 1: somalier extract 
# 2: somalier relate（QUERY_SITE_VCFを与えるとコンタミ判定もしてもらえる？）
# 2-2: 2の結果から各サンプルのscaled X or Y depthのリストを作る（男女判定が合うか確認用）
# 3: somalier ancestry
set -euo pipefail

REF_SITE_VCF=inputs/sites.GRCh37.vcf.gz 
#REF_SITE_VCF=inputs/sites.hg38.vcf.gz 
QUERY_VCF=inputs/joint.vcf.gz
REF_FA=inputs/human_g1k_v37.fasta
#REF_FA=inputs/human_GRCh38_no_alt_analysis_set.fasta
#REF_FA=inputs/Homo_sapiens_assembly38.fasta
PED=inputs/samples.ped
IMG=brentp/somalier:v0.3.3


# 1
docker run --rm \
    -v /betelgeuse10:/betelgeuse10 \
    -v /antares01:/antares01 \
    -w $(pwd) \
    $IMG \
    somalier extract \
    -d results/extract/ \
    --sites $REF_SITE_VCF \
    -f $REF_FA \
    $QUERY_VCF \
    > logs/extract.log 2>&1


# 2
docker run --rm \
    -v /betelgeuse10:/betelgeuse10 \
    -v /antares01:/antares01 \
    -w $(pwd) \
    $IMG \
    somalier relate \
    -p $PED \
    -o results/relate/somalier \
    results/extract/*.somalier \
    > logs/relate.log 2>&1
    #-s $QUERY_SITE_VCF \ # charrを計算する時
    #-e SOMALIER_REPORT_ALL_PAIRS=1 \


# 2-2
gawk 'BEGIN{print "sample\tsex\tx_depth_mean\ty_depth_mean"}
    match($0, /"sample":"([^"]+)"[^}]+"sex":"([^"]+)"[^}]+"x_depth_mean":([0-9.e+-]+)[^}]+"y_depth_mean":([0-9.e+-]+)/, a) {
        print a[1], a[2], a[3], a[4]
    }' OFS='\t' results/relate/somalier.html \
    > results/relate/sample_x_y_depth.list


# 3
LABEL_1KG=inputs/ancestry-labels-1kg.tsv 
docker run --rm \
    -v /betelgeuse10:/betelgeuse10 \
    -v /antares01:/antares01 \
    -w $(pwd) \
    $IMG \
    somalier ancestry \
    -o results/somalier-ancestry \
    --labels $LABEL_1KG \
    inputs/1kg-somalier/*.somalier \
    ++ \
    results/extract/*.somalier \
    > logs/ancestry.log 2>&1



#import pandas as pd
#df = pd.read_table("results/relate/somalier.pairs.tsv")
#df = df[["#sample_a", "sample_b", "relatedness"]]
#pd.concat([
#	df.rename({"#sample_a":"1","sample_b":"2"},axis=1), 
#	df.rename({"#sample_a":"2","sample_b":"1"},axis=1)]
#).\
#groupby("1").\
#sum("relatedness").\
#reset_index().\
#sort_values("relatedness").\
#tail(60)
