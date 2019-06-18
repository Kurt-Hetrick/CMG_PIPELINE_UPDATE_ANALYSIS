#!/bin/bash

# INPUT ARGUMENTS

	INPUT_VCF=$1 # full path to multi-sample vcf that you are validating. needs to be tabix/bgzipped
		INPUT_VCF_PREFIX=`basename $INPUT_VCF vcf.gz`
	PHENODB_REPORT=$2 # path to the text file
		PHENODB_REPORT_PREFIX=`basename $PHENODB_REPORT .txt`

	# PHENODB_REPORT="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results/FinalResultsSearch-28August2018.txt"

# OTHER VARIABLES

	WORKING_DIRECTORY="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results"
	REFERENCE_GENOME="/mnt/research/tools/PIPELINE_FILES/bwa_mem_0.7.5a_ref/human_g1k_v37_decoy.fasta"
	CANDIDATE_SNPS_VCF="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results/FinalResultsSearch-28August2018.REFORMATED.SNV.clean.ann.sites.vcf.gz"
	CANDIDATE_INDELS_VCF="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results/FinalResultsSearch-28August2018.REFORMATED.INDEL.5bpPAD.fixed.results.DaN.hand.vcf.gz"

	# this really needs to be an input variable, but this will do for now.
	MASTER_KEY="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/01_ARCHIVE/CMG_PIPELINE_UPDATE_ANALYSIS/results/MasterSampleKey_090418_11433_all.csv"

#####################################################
##### CHECK THE VCF FOR THE CANDIDATE SNP SITES #####
#####################################################

	# awk '{print "tabix",\
	# 	"'$INPUT_VCF'",$1":"$3"-"$3}' \
	# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.SNV.bed" \
	# 	| bash \
	# 	| cut -f 1-8 \
	# 	| egrep "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
	# 	| awk 'BEGIN {OFS="\t"} {print $1,$2-1,$2,$3,$4"->"$5,$6,$7,$8}' \
	# 	| bedtools intersect -wao -a $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.SNV.bed" -b - \
	# 	| sed 's/|/\t/g' \
	# >| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt"

	# SNP_COUNT=`wc -l $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt" | awk '{print $1}'`

	# echo
	# echo there are $SNP_COUNT snps in the vcf file out of 181 candidate snp loci
	# echo this is the distribution of FILTER
	# echo `cut -f 13 $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt" | sort | uniq -c`
	# echo
	# echo now checking to see if the alleles match
	# # i'm not decomposing the vcf before doing this on purpose

	# awk 'BEGIN {FS="\t";OFS="\t"} $4!=$11 {print $1,$2,$3,$4,$6,$7,$8,$9,$10,$11,$12,$13"\n"}' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.bed.vcf.txt"
	
	# echo done
	# echo waiting for 10 seconds
	# sleep 10s

##################################################
##### NOW MAKING A VCF OF THE CANDIDATE SNPS #####
##################################################

	echo now formatting, decomposing and normalizing vcf for snps

	awk '{print "tabix",\
	"'$INPUT_VCF'",$1":"$3"-"$3}' \
	$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.SNV.bed" \
		| bash \
		| egrep "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
	>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf"

	# MAKE A DECOMPOSED, NORMALIZED AND SORTED BY REF VCF

		( tabix -H $INPUT_VCF ; \
		awk '$1!="X"' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf" | sort -k 1,1n -k 2,2n ; \
		awk '$1=="X"' $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.results.vcf" | sort -k 2,2n ) \
			| vt decompose -s - \
			| vt normalize -r $REFERENCE_GENOME - \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf"

	# REMOVE STAR ALLELES.

		( grep ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf" ; \
		grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.vcf" \
		| awk '$5!="*"' ) \
		| bgzip \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf.gz"

		tabix -p vcf $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf.gz"

	# do an exact match using bcftools isec

		bcftools \
		isec \
			-n=2 \
			-w1 \
			--output $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf" \
			--output-type v \
			$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.DaN.NoStar.vcf.gz" \
			$CANDIDATE_SNPS_VCF

		echo sleeping for 10 seconds
		sleep 10s
		echo annotating vcf with samples that are non-reference

	# ANNOTATE THE VCF WITH SAMPLE IDS

		/mnt/linuxtools/JAVA/jdk1.8.0_73/bin/java -jar \
		/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
		-T VariantAnnotator \
		-R $REFERENCE_GENOME \
		--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf" \
		-L $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.vcf" \
		-A GenotypeSummaries \
		-A VariantType \
		-A SampleList \
		-o $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf"

	# MAKE A SITES ONLY VCF

		( grep ^## $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" ; \
		grep ^#C $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" \
		| cut -f 1-8 ; \
		grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.vcf" \
		| cut -f 1-8 ) \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.sites.vcf"

	# VALIDATE SNP C0UNT

		SNP_COUNT=`grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.sites.vcf" | wc -l |  awk '{print $1}'`

		echo
		echo there are $SNP_COUNT snps in the vcf file out of 181 candidate snp loci
		echo this is the distribution of FILTER
		echo `grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.sites.vcf" | cut -f 7 | sort | uniq -c`
		echo

		echo now going to do INDELS
		echo sleep for 10 seconds
		echo

###################################################
#### NOW MAKING A VCF OF THE CANDIDATE INDELS #####
###################################################

	# GRAB THE INDEL RESULTS

		awk '{print "tabix","'$INPUT_VCF'",$1":"$2"-"$3}' \
		$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.bed" \
			| bash \
			| cut -f 1-8 \
			| egrep -v "VariantType=SNP|VariantType=MULTIALLELIC_SNP" \
			| sort -k 1,1n -k 2,2n \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.vcf"

	# DECOMPOSE AND NORMALIZE

		( tabix -H $INPUT_VCF | grep ^## ; \
		tabix -H $INPUT_VCF | grep -v ^## | cut -f 1-8 ; \
		cat $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.vcf" ) \
			| vt decompose -s - \
			| vt normalize -r $REFERENCE_GENOME - \
		>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.vcf"


	# REMOVE STAR ALLELES.

			( grep ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.vcf" ; \
			grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.vcf" \
			| awk '$5!="*"' ) \
			| bgzip \
			>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.NoStar.vcf.gz"

			tabix -p vcf $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.NoStar.vcf.gz"

	# do an exact match using bcftools isec

			bcftools \
			isec \
				-n=2 \
				-w1 \
				--output $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.vcf" \
				--output-type v \
				$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.5bpPAD.fixed.results.DaN.NoStar.vcf.gz" \
				$CANDIDATE_INDELS_VCF

			echo sleeping for 10 seconds
			sleep 10s
			echo annotating vcf with samples that are non-reference

		# ANNOTATE THE VCF WITH SAMPLE IDS

			/mnt/linuxtools/JAVA/jdk1.8.0_73/bin/java -jar \
			/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
			-T VariantAnnotator \
			-R $REFERENCE_GENOME \
			--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.vcf" \
			-L $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.vcf" \
			-A GenotypeSummaries \
			-A VariantType \
			-A SampleList \
			-o $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.vcf"

		# MAKE A SITES ONLY VCF

			( grep ^## $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.vcf" ; \
			grep ^#C $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.vcf" \
			| cut -f 1-8 ; \
			grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.vcf" \
			| cut -f 1-8 ) \
			>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.sites.vcf"

		# VALIDATE INDEL C0UNT

			INDEL_COUNT=`grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.sites.vcf" | wc -l |  awk '{print $1}'`

			echo
			echo there are $INDEL_COUNT snps in the vcf file out of 30 candidate snp loci
			echo this is the distribution of FILTER
			echo `grep -v ^# $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.sites.vcf" | cut -f 7 | sort | uniq -c`
			echo

	# combine variants into one file

		java -jar /mnt/research/tools/LINUX/GATK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
		-T CombineVariants \
		--disable_auto_index_creation_and_locking_when_reading_rods \
		-R $REFERENCE_GENOME \
		--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.SNV.clean.ann.sites.vcf" \
		--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".REFORMATED.INDEL.clean.ann.sites.vcf" \
		--genotypemergeoption UNSORTED \
		-o $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.vcf.gz"

	# turn into a table

		/mnt/linuxtools/JAVA/jdk1.8.0_73/bin/java -jar \
		/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
		-T VariantsToTable \
		--disable_auto_index_creation_and_locking_when_reading_rods \
		-R $REFERENCE_GENOME \
		--variant $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.vcf.gz" \
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
		-o $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.txt"

			# explode table into a record per sample/loci...this is for matching on the sm tag to local id

				awk 'BEGIN {OFS="\t"} NR>1 {print $0,$23}' \
				$WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.txt" \
					| awk 'BEGIN {OFS="\t"} {split($36,sample,","); for (i in sample) {print sample[i],$0}}' \
					| cut -f 1-36 \
				>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.explode.txt"

				shorten_table_path=`ls $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".final.explode.txt"`

			# match the master key against exploded table to get local id

				cut -d "," -f 3,5 $MASTER_KEY \
				| sed 's/,/\t/g' \
				| awk 'NR>1' \
				| awk '{print "awk","\x27","$1==\x22" $1 "\x22" , "{print \x22" $2 "\x22,$0}\x27", "'$shorten_table_path'"}' \
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
				>| $WORKING_DIRECTORY/$PHENODB_REPORT_PREFIX"_"$INPUT_VCF_PREFIX".LOCAL_ID.COLLAPSED.txt"
