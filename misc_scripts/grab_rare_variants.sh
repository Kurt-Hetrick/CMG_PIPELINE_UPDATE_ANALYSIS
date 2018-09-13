#!/bin/bash

# INPUT VARIABLES

	IN_VCF=$1 # /mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1_NEW/MULTI_SAMPLE/M_Valle_MD_SeqWholeExome_120417_1_NEW_2536.BEDsuperset.VQSR.vcf.gz
		VCF_PREFIX=$(basename $IN_VCF .BEDsuperset.VQSR.vcf.gz)
	OUT_DIR=$2
	RARE_SNP_BED_FILE=$3 # FinalResultsSearch-28August2018.REFORMATED.SNV.bed
	RARE_INDEL_BED_FILE=$4 # FinalResultsSearch-28August2018.REFORMATED.INDEL.5bpPAD.fixed.bed
	MASTER_KEY=$5 # MasterSampleKey_090418_11433_all.csv

# STATIC_VARIABLES

	JAVA_1_8="/mnt/research/tools/LINUX/JAVA/jdk1.8.0_73/bin"
	GATK_DIR="/mnt/research/tools/LINUX/GATK/GenomeAnalysisTK-3.7"

	REF_GENOME="/isilon/sequencing/GATK_resource_bundle/1.5/b37/human_g1k_v37_decoy.fasta"

#####################
##### RARE SNPS #####
#####################

# grab the header from the vcf

	tabix -h \
	$IN_VCF Y \
	| grep ^# \
	>| $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf"

# grab the rare snps

	awk '{print "tabix",\
	"'$IN_VCF'",$1":"$3"-"$3}' \
	$RARE_SNP_BED_FILE \
	| bash \
	| egrep "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
	>> $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf"

# do reference chromosome sorting

	# grab the header

		grep "^#" $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
		>| $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf"

	# sort the records

		# autosomes
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| awk '$1~/^[0-9]/' $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf"

		# X
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| awk '$1=="X"' $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf"

		# Y
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| awk '$1=="Y"' $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf"

		# MT
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| awk '$1=="MT"' $OUT_DIR/$VCF_PREFIX".RARE.SNP.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf"


# what are the allele counts

	$JAVA_1_8/java -jar \
	$GATK_DIR/GenomeAnalysisTK.jar \
	-T VariantsToTable \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	-R $REF_GENOME \
	--variant $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.vcf" \
	-F CHROM \
	-F POS \
	-F ID \
	-F REF \
	-F ALT \
	-F QUAL \
	-F TYPE \
	-F MULTI-ALLELIC \
	-F EVENTLENGTH \
	-F FILTER \
	-F AC \
	-F AN \
	-F AF \
	-F ABHet \
	-F ABHom \
	-F HET \
	-F HOM-VAR \
	-F NSAMPLES \
	-F NO-CALL \
	-F GQ_MEAN \
	-F GQ_STDDEV \
	-F NDA \
	-F Samples \
	-F DP \
	-F QD \
	-F GC \
	-F FS \
	-F SOR \
	-F MQ \
	-F MQRankSum \
	-F ReadPosRankSum \
	-F culprit \
	-F VQSLOD \
	-F POSITIVE_TRAIN_SITE \
	-F NEGATIVE_TRAIN_SITE \
	-AMD \
	-raw \
	-o $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.txt"

# summarize

	awk 'NR>1 {variants+=($10=="PASS")} {sum+=$11} \
		END {print "there are",variants,"passing SNPs in this call set""\n"\
		"there should be 181""\n"\
		"the allele count is",sum}' \
	$OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.txt" \
	>| $OUT_DIR/$VCF_PREFIX".RARE.SNP.validate.callset.txt"

# explode the sample lists into a record for each genotype

	awk 'BEGIN {OFS="\t"} NR>1 {print $0,$23}' $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.txt" \
		| awk 'BEGIN {OFS="\t"} {split($36,sample,","); for (i in sample) {print sample[i],$0}}' \
		| cut -f 1-36 \
	>| $OUT_DIR/$VCF_PREFIX".RARE.SNP.SORTED.EXPLODED.txt"


# print the header for the final output

# match on the SM_TAG to extract the LOCAL_ID

	cut -d "," -f 3,5 $MASTER_KEY \
		| sed 's/,/\t/g' \
		| awk 'NR>1' \
		| awk '{print "awk","\x27","$1==\x22" $1 "\x22" , "{print \x22" $2 "\x22,$0}\x27","'$OUT_DIR'" "/" "'$VCF_PREFIX'" ".RARE.SNP.SORTED.EXPLODED.txt"}' \
		| bash \
		| awk 'BEGIN {OFS="\t"} {split($1,LOCAL_ID,"_"); print LOCAL_ID[1],$0}' \
		| sed 's/ /\t/g' \
		| sort -k 4,4 -k 5,5n -k 1,1 \
		| datamash \
			-g 4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,27,28,29,30,31,32,33,34,35,36,37,38 \
			unique 1 \
			collapse 2 \
			collapse 3 \
		| awk 'BEGIN {print "CHROM", \
			"POS" , \
			"ID", \
			"REF", \
			"ALT", \
			"QUAL", \
			"TYPE", \
			"MULTI-ALLELIC", \
			"EVENTLENGTH", \
			"FILTER", \
			"AC", \
			"AN", \
			"AF", \
			"ABHet", \
			"ABHom", \
			"HET", \
			"HOM-VAR", \
			"NSAMPLES", \
			"NO-CALL", \
			"GQ_MEAN", \
			"GQ_STDDEV", \
			"NDA", \
			"DP", \
			"QD", \
			"GC", \
			"FS", \
			"SOR", \
			"MQ", \
			"MQRankSum", \
			"ReadPosRankSum", \
			"culprit", \
			"VQSLOD", \
			"POSITIVE_TRAIN_SITE", \
			"NEGATIVE_TRAIN_SITE", \
			"FAMILIES", \
			"LOCAL_IDS", \
			"SM_TAGS"} \
			{print $0}' \
		| sed 's/ /\t/g' \
	>| $OUT_DIR/$VCF_PREFIX".RARE.SNP.LOCAL_ID.COLLAPSED.txt"

#######################
##### RARE INDELS #####
#######################

# grab the header from the vcf

	tabix -h \
	$IN_VCF Y \
	| grep ^# \
	>| $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf"

# grab the rare snps

	awk '{print "tabix",\
	"'$IN_VCF'",$1":"$2"-"$3}' \
	$RARE_INDEL_BED_FILE \
	| bash \
	| egrep -v "VariantType=SNP" \
	| awk '$5!~"*" {print $0}' \
	>> $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf"

# do reference chromosome sorting

	# grab the header

		grep "^#" $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
		>| $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf"

	# sort the records

		# autosomes
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| awk '$1~/^[0-9]/' $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf"

		# X
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| awk '$1=="X"' $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf"

		# Y
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| awk '$1=="Y"' $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf"

		# MT
		grep -v "^#" $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| awk '$1=="MT"' $OUT_DIR/$VCF_PREFIX".RARE.INDEL.vcf" \
			| sort -k1,1n -k2,2n \
		>> $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf"

# what are the allele counts

	$JAVA_1_8/java -jar \
	$GATK_DIR/GenomeAnalysisTK.jar \
	-T VariantsToTable \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	-R $REF_GENOME \
	--variant $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.vcf" \
	-F CHROM \
	-F POS \
	-F ID \
	-F REF \
	-F ALT \
	-F QUAL \
	-F TYPE \
	-F MULTI-ALLELIC \
	-F EVENTLENGTH \
	-F FILTER \
	-F AC \
	-F AN \
	-F AF \
	-F ABHet \
	-F ABHom \
	-F HET \
	-F HOM-VAR \
	-F NSAMPLES \
	-F NO-CALL \
	-F GQ_MEAN \
	-F GQ_STDDEV \
	-F NDA \
	-F Samples \
	-F DP \
	-F QD \
	-F GC \
	-F FS \
	-F SOR \
	-F MQ \
	-F MQRankSum \
	-F ReadPosRankSum \
	-F culprit \
	-F VQSLOD \
	-F POSITIVE_TRAIN_SITE \
	-F NEGATIVE_TRAIN_SITE \
	-AMD \
	-raw \
	-o $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.txt"

# summarize

	awk 'NR>1 {variants+=($10=="PASS")} {sum+=$11} \
		END {print "there are",variants,"passing INDELs in this call set""\n"\
		"there should be 32""\n"\
		"the allele count is",sum}'\
	$OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.txt" \
	>| $OUT_DIR/$VCF_PREFIX".RARE.INDEL.validate.callset.txt"

# explode the sample lists into a record for each genotype

	awk 'BEGIN {OFS="\t"} NR>1 {print $0,$23}' $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.txt" \
		| awk 'BEGIN {OFS="\t"} {split($36,sample,","); for (i in sample) {print sample[i],$0}}' \
		| cut -f 1-36 \
	>| $OUT_DIR/$VCF_PREFIX".RARE.INDEL.SORTED.EXPLODED.txt"

# match on the SM_TAG to extract the LOCAL_ID

	cut -d "," -f 3,5 $MASTER_KEY \
		| sed 's/,/\t/g' \
		| awk 'NR>1' \
		| awk '{print "awk","\x27","$1==\x22" $1 "\x22" , "{print \x22" $2 "\x22,$0}\x27","'$OUT_DIR'" "/" "'$VCF_PREFIX'" ".RARE.INDEL.SORTED.EXPLODED.txt"}' \
		| bash \
		| awk 'BEGIN {OFS="\t"} {split($1,LOCAL_ID,"_"); print LOCAL_ID[1],$0}' \
		| sed 's/ /\t/g' \
		| sort -k 4,4 -k 5,5n -k 1,1 \
		| datamash \
			-g 4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,27,28,29,30,31,32,33,34,35,36,37,38 \
			unique 1 \
			collapse 2 \
			collapse 3 \
		| awk 'BEGIN {print "CHROM", \
			"POS" , \
			"ID", \
			"REF", \
			"ALT", \
			"QUAL", \
			"TYPE", \
			"MULTI-ALLELIC", \
			"EVENTLENGTH", \
			"FILTER", \
			"AC", \
			"AN", \
			"AF", \
			"ABHet", \
			"ABHom", \
			"HET", \
			"HOM-VAR", \
			"NSAMPLES", \
			"NO-CALL", \
			"GQ_MEAN", \
			"GQ_STDDEV", \
			"NDA", \
			"DP", \
			"QD", \
			"GC", \
			"FS", \
			"SOR", \
			"MQ", \
			"MQRankSum", \
			"ReadPosRankSum", \
			"culprit", \
			"VQSLOD", \
			"POSITIVE_TRAIN_SITE", \
			"NEGATIVE_TRAIN_SITE", \
			"FAMILIES", \
			"LOCAL_IDS", \
			"SM_TAGS"} \
			{print $0}' \
		| sed 's/ /\t/g' \
	>| $OUT_DIR/$VCF_PREFIX".RARE.INDEL.LOCAL_ID.COLLAPSED.txt"
