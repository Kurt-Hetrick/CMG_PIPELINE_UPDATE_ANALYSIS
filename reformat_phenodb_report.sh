#!/bin/bash

# INPUT ARGUMENTS

	$1=PHENODB_REPORT # path to the text file
		PHENODB_REPORT_PREFIX=`basename $PHENODB_REPORT .txt`

		#############################################################################
		#### 1. in phenodb search/goto; #############################################
		########## "waiting for report to be issued." click on link #################
		#############################################################################
		#### 2. go to the bottom of page ############################################
		########## Download submissions final results table as tab-delimited text ###
		#############################################################################

# other variables.

	WORKING_DIRECTORY="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results"

# reformat phenodb output

	sed '/^$/d' $PHENODB_REPORT \
		| egrep -v "Date|Submission" \
		| awk 'BEGIN {FS="\t";OFS="\t"} $15!="" {print $2,$3,$4,$6,$7,$8,$1,$15} $15=="" {print $2,$3,$4,$6,$7,$8,$1,"NOT_LISTED"}' \
		| sed 's/chr//g' \
		| sed 's/,//g' \
		| sort -k 1,1 -k2,2n -k3,3n \
		| datamash -g 1,2,3,4,5,6 collapse 7 collapse 8 \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.txt"

# convert into a bed file and add 5 bp pad

	awk 'BEGIN {OFS="\t"} $6=="SNV" {print $1,$2-1,$3,$4"->"$5"|"$7} $6=="Indel" {print $1,$2-5,$3+5,$4"->"$5"|"$7}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.txt" \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.5bpPAD.bed"

# convert the snps to a bed file

	awk 'BEGIN {FS="\t";OFS="\t"} $6=="SNV" {print $1,$2-1,$3,$4"->"$5,$7,$8$9$10}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.txt" \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.SNV.bed"

# convert the indels to a bed file

	awk 'BEGIN {FS="\t";OFS="\t"} $6=="Indel" {print $1,$2-5,$3+5,$4"->"$5,$7,$8$9$10}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.txt" \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.INDEL.5bpPAD.bed"

# variant counts

VARIANT_COUNT=`wc -l $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.5bpPAD.bed"`

SNP_COUNT=`wc -l $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.SNV.bed"`

INDEL_COUNT=`wc -l $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.INDEL.5bpPAD.bed"`

echo
echo there are $VARIANT_COUNT in the phenodb results output

echo
echo there are $SNP_COUNT in the phenodb results output

echo
echo there are $INDEL_COUNT in the phendobp results output

echo there are really 30 indels because
echo 1 I remove because it is a false positive from bacterial dna
echo 2 I remove because they are candidates that arised from a unified genotyper bug where it assigned the incorrect genotypes to the wrong sample
echo 1 I merge with another b/c they are the same even though the annovar reports have different end positions by 1 bp
echo
echo the fixed files is named FinalResultsSearch-28August2018.REFORMATED.INDEL.5bpPAD.bed
echo I merge these outputs back together and resort them so that it is easier to check for compound heterozygotes
echo file name is files is named FinalResultsSearch-28August2018.REFORMATED.INDEL.5bpPAD.fixed.bed
