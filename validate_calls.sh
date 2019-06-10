#!/bin/bash

# INPUT ARGUMENTS

	$1=INPUT_VCF # full path to multi-sample vcf that you are validating. needs to be tabix/bgzipped
		INPUT_VCF_PREFIX=`basename $INPUT_VCF vcf.gz`
	$2=PHENODB_REPORT # path to the text file
		PHENODB_REPORT_PREFIX=`basename $PHENODB_REPORT .txt`

	# PHENODB_REPORT="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results/FinalResultsSearch-28August2018.txt"

# OTHER VARIABLES

	WORKING_DIRECTORY="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results"
	REFERENCE_GENOME="/mnt/research/tools/PIPELINE_FILES/bwa_mem_0.7.5a_ref/human_g1k_v37_decoy.fasta"

# CHECK THE VCF FOR THE CANDIDATE SNP SITES

	awk '{print "tabix",\
		"'$INPUT_VCF'",$1":"$3"-"$3}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed" \
		| bash \
		| cut -f 1-8 \
		| egrep "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
		| awk 'BEGIN {OFS="\t"} {print $1,$2-1,$2,$3,$4"->"$5,$6,$7,$8}' \
		| bedtools intersect -wao -a $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed" -b - \
		| sed 's/|/\t/g' \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt"

	SNP_COUNT=`wc -l $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt"`

	echo
	echo there are $SNP_COUNT snps in the vcf file out of 181 candidate snp loci
	echo this is the distribution of FILTER
	echo `cut -f 13 $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt" | sort | uniq -c`
	echo
	echo now checking to see if the alleles match
	# i'm not decomposing the vcf before doing this on purpose
	echo `awk 'BEGIN {FS="\t";OFS="\t"} $4!=$11 {print $1,$2,$3,$4,$6,$7,$8,$9,$10,$11,$12,$13}' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt"`
	echo done

# NOW MAKING A VCF OF THE CANDIDATE SNPS

	awk '{print "tabix",\
	"'$INPUT_VCF'",$1":"$3"-"$3}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.bed" \
		| bash \
		| egrep "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf"

	# MAKE A DECOMPOSED, NORMALIZED AND SORTED BY REF VCF

		( tabix -H $INPUT_VCF ; \
		awk '$1!="X"' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf" | sort -k 1,1n -k 2,2n ; \
		awk '$1=="X"' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf" | sort -k 2,2n ) \
			| vt decompose -s - \
			| vt normalize -r $REFERENCE_GENOME - \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf"

	# REMOVE STAR ALLELES.

		( grep ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf" ; \
		grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf" \
		| awk '$5!="*"' ) \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf"

	# REMOVE WRONG ALLE FROM A SNP DECOMPOSED FROM A MULTI-ALLELIC SITE.

		WRONG_ALLELE=`grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf" | awk '$1=="16"&&$2=="15809106"&&$5=="A" {print NR}'`

		( grep ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf" ; \
		grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf" \
		| awk 'NR!=133' ) \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf"

	# ANNOTATE THE VCF WITH SAMPLE IDS

		/mnt/linuxtools/JAVA/jdk1.8.0_73/bin/java -jar \
		/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
		-T VariantAnnotator \
		-R $REFERENCE_GENOME \
		--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf" \
		-L $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf" \
		-A GenotypeSummaries \
		-A VariantType \
		-A SampleList \
		-o $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf"

	# MAKE A SITES ONLY VCF

		( grep ^## $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" ; \
		grep ^#C $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" \
		| cut -f 1-8 ; \
		grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" \
		| cut -f 1-8 ) \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.sites.vcf"






