#! /bin/bash

###################
# INPUT VARIABLES #
###################

	PROJECT_MS=$1 # the project where the multi-sample vcf is being written to
	SAMPLE_SHEET=$2 # full/relative path to the sample sheet
	PREFIX=$3 # prefix name that you want to give the multi-sample vcf
	NUMBER_OF_BED_FILES=$4 # scatter count, if not supplied then the default is what is below.

		# if there is no 4th argument present then use the number for the scatter count
		if [[ ! $NUMBER_OF_BED_FILES ]]
			then
			NUMBER_OF_BED_FILES=500
		fi

###########################
# CORE VARIABLES/SETTINGS #
###########################

	# gcc is so that it can be pushed out to the compute nodes via qsub (-V)
	module load gcc/5.1.0

	# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED
	SCRIPT_DIR="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CMG_PIPELINE_UPDATE_ANALYSIS/scripts/"

	# Directory where sequencing projects are located
	CORE_PATH="/mnt/research/active"

	# Generate a list of active queue and remove the ones that I don't want to use
	QUEUE_LIST=`qstat -f -s r \
	 | egrep -v "^[0-9]|^-|^queue" \
	 | cut -d @ -f 1 \
	 | sort \
	 | uniq \
	 | egrep -v "bigmem.q|all.q|cgc.q|programmers.q|rhel7.q|qtest.q" \
	 | datamash collapse 1 \
	 | awk '{print $1}'`

	 # | awk '{print $1,"-l \x27hostname=!DellR730-03\x27"}'`

	# EVENTUALLY I WANT THIS SET UP AS AN OPTION WITH A DEFAULT OF X

	PRIORITY="-20"

	# eventually, i want to push this out to something...maybe in the vcf file header.
	PIPELINE_VERSION=`git --git-dir=$SCRIPT_DIR/../.git --work-tree=$SCRIPT_DIR/.. log --pretty=format:'%h' -n 1`

	# generate a random number b/w "0 - 32767" to be used for the job name for variant annotator both pre and post refinement
	# this is to help cut down on the job name length so I can increase the scatter count
	HACK=(`echo $RANDOM`)

	# TIMESTAMP=`date '+%F.%H-%M-%S'`

#####################
# PIPELINE PROGRAMS #
#####################

	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	BEDTOOLS_DIR="/mnt/linuxtools/BEDTOOLS/bedtools-2.22.0/bin"
	GATK_DIR="/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7"
	SAMTOOLS_0118_DIR="/mnt/linuxtools/SAMTOOLS/samtools-0.1.18"
		# Becasue I didn't want to go through compiling this yet for version 1.6...I'm hoping that Keith will eventually do a full OS install of RHEL7 instead of his
		# typical stripped down installations so I don't have to install multiple libraries again
	TABIX_DIR="/mnt/linuxtools/TABIX/tabix-0.2.6"
	CIDRSEQSUITE_JAVA_DIR="/mnt/linuxtools/JAVA/jre1.7.0_45/bin"
	CIDRSEQSUITE_6_1_1_DIR="/mnt/linuxtools/CIDRSEQSUITE/6.1.1"
	CIDRSEQSUITE_ANNOVAR_JAVA="/mnt/linuxtools/JAVA/jre1.6.0_25/bin"
	CIDRSEQSUITE_DIR_4_0="/mnt/research/tools/LINUX/CIDRSEQSUITE/Version_4_0"
	CIDRSEQSUITE_PROPS_DIR="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CIDR_SEQ_CAPTURE_JOINT_CALL/STD_VQSR"
		# cp -p /u01/home/hling/cidrseqsuite.props.HGMD /mnt/research/tools/LINUX/00_GIT_REPO_KURT/CIDR_SEQ_CAPTURE_JOINT_CALL/STD_VQSR/cidrseqsuite.props
		# 14 June 2018
	CIDRSEQSUITE_7_5_0_DIR="/mnt/research/tools/LINUX/CIDRSEQSUITE/7.5.0"
		# Copied from \\isilon-cifs\sequencing\CIDRSeqSuiteSoftware\RELEASES\7.0.0\QC_REPORT\EnhancedSequencingQCReport.jar
	LAB_QC_DIR="/mnt/linuxtools/CUSTOM_CIDR/EnhancedSequencingQCReport/0.0.2"
	SAMTOOLS_DIR="/isilon/sequencing/Kurt/Programs/PYTHON/Anaconda2-5.0.0.1/bin/"
		# This is samtools version 1.5
		# I have no idea why other users other than me cannot index a cram file with a version of samtools that I built from the source
		# Apparently the version that I built with Anaconda works for other users, but it performs REF_CACHE first...
	DATAMASH_DIR="/mnt/research/tools/LINUX/DATAMASH/datamash-1.0.6"
	TABIX_DIR="/mnt/research/tools/LINUX/TABIX/tabix-0.2.6"

##################
# PIPELINE FILES #
##################

	HAPMAP_VCF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/hapmap_3.3.b37.vcf"
	OMNI_VCF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/1000G_omni2.5.b37.vcf"
	ONEKG_SNPS_VCF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/1000G_phase1.snps.high_confidence.b37.vcf"
	DBSNP_138_VCF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/dbsnp_138.b37.vcf"
	ONEKG_INDELS_VCF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
	P3_1KG="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/ALL.wgs.phase3_shapeit2_mvncall_integrated_v5.20130502.sites.vcf.gz"
	ExAC="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/ExAC.r0.3.sites.vep.vcf.gz"
	KNOWN_SNPS="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/dbsnp_138.b37.excluding_sites_after_129.vcf"
	VERACODE_CSV="/mnt/linuxtools/CIDRSEQSUITE/Veracode_hg18_hg19.csv"
	MERGED_MENDEL_BED_FILE="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914.bed"

##################################################
##################################################
##### JOINT CALLING PROJECT SET-UP ###############
### WHERE THE MULTI-SAMPLE VCF GETS WRITTEN TO ###
##################################################
##################################################

	# This checks to see if bed file directory and split gvcf list has been created from a previous run.
	# If so, remove them to not interfere with current run

		if [ -d $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT ]
			then
				rm -rf $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT
		fi

		if [ -d $CORE_PATH/$PROJECT_MS/TEMP/SPLIT_SS ]
			then
				rm -rf $CORE_PATH/$PROJECT_MS/TEMP/SPLIT_SS
		fi

############################################################################################
##### MAKE THE FOLLOWING FOLDERS IN THE PROJECT WHERE THE MULTI-SAMPLE VCF IS GOING TO #####
############################################################################################

	mkdir -p $CORE_PATH/$PROJECT_MS/{LOGS,COMMAND_LINES}
	mkdir -p $CORE_PATH/$PROJECT_MS/TEMP/{BED_FILE_SPLIT,AGGREGATE,QC_REPORT_PREP_$PREFIX,SPLIT_SS}
	mkdir -p $CORE_PATH/$PROJECT_MS/MULTI_SAMPLE/VARIANT_SUMMARY_STAT_VCF/
	mkdir -p $CORE_PATH/$PROJECT_MS/GVCF/AGGREGATE
	mkdir -p $CORE_PATH/$PROJECT_MS/REPORTS/{ANNOVAR,LAB_PREP_REPORTS_MS,QC_REPORTS,QC_REPORT_PREP_$PREFIX}
	mkdir -p $CORE_PATH/$PROJECT_MS/TEMP/ANNOVAR/$PREFIX
	mkdir -p $CORE_PATH/$PROJECT_MS/LOGS/{A01_COMBINE_GVCF,B01_GENOTYPE_GVCF,C01_VARIANT_ANNOTATOR}

##################################################
### FUNCTIONS FOR JOINT CALLING PROJECT SET-UP ###
##################################################

	# grab the reference genome file, dbsnp file and bait bed file for the "project"
	## !should do a check here to make sure that there is only one record...!

		CREATE_PROJECT_INFO_ARRAY ()
		{
			PROJECT_INFO_ARRAY=(`sed 's/\r//g' $SAMPLE_SHEET \
				| awk 'BEGIN{FS=","} NR>1 {print $12,$18,$16}' \
				| sed 's/,/\t/g' \
				| sort -k 1,1 \
				| awk '{print $1,$2,$3}' \
				| sort \
				| uniq`)

			REF_GENOME=${PROJECT_INFO_ARRAY[0]} # field 12 from the sample sheet
			PROJECT_DBSNP=${PROJECT_INFO_ARRAY[1]} # field 18 from the sample sheet
			PROJECT_BAIT_BED=${PROJECT_INFO_ARRAY[2]} # field 16 from the sample sheet
		}

	# Keep this in here to reference...I'll probably going to use this somewhere.
	# generates a chrosome list from a bait bed file at the project level. so I only have to make one iteration per project instead of one per sample

		# CREATE_CHROMOSOME_LIST ()
		# {
		# REF_CHROM_SET=$(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $PROJECT_BAIT_BED \
		# | sed -r 's/[[:space:]]+/\t/g' \
		# | cut -f 1 \
		# | sort \
		# | uniq \
		# | $DATAMASH_DIR/datamash collapse 1 | sed 's/,/ /g')
	# }	

	# GET RID OF ALL THE COMMON BED FILE EFF-UPS,

		FORMAT_AND_SCATTER_BAIT_BED ()
		{
		BED_FILE_PREFIX=(`echo BF`)

			# make sure that there is EOF
			# remove CARRIAGE RETURNS
			# remove CHR PREFIXES (THIS IS FOR GRCH37)
			# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.

				awk 1 $MERGED_MENDEL_BED_FILE | sed -r 's/\r//g ; s/chr//g ; s/[[:space:]]+/\t/g' \
				>| $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_BED_FILE.bed

				# SORT TO GRCH37 ORDER
				(awk '$1~/^[0-9]/' $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_BED_FILE.bed | sort -k1,1n -k2,2n ; \
				 	awk '$1=="X"' $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_BED_FILE.bed | sort -k 2,2n ; \
				 	awk '$1=="Y"' $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_BED_FILE.bed | sort -k 2,2n ; \
				 	awk '$1=="MT"' $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_BED_FILE.bed | sort -k 2,2n) \
				>| $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_AND_SORTED_BED_FILE.bed

			# Determining how many records will be in each mini-bed file.
			# The +1 at the end is to round up the number of records per mini-bed file to ensure all records are captured.
			# So the last mini-bed file will be smaller.
			# IIRC. this statement isn't really true, but I don't feel like figuring it out right now. KNH

				INTERVALS_DIVIDED=`wc -l $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_AND_SORTED_BED_FILE.bed \
					| awk '{print $1"/""'$NUMBER_OF_BED_FILES'"}' \
					| bc \
					| awk '{print $0+1}'`

				split -l $INTERVALS_DIVIDED -a 4 -d \
					$CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/FORMATTED_AND_SORTED_BED_FILE.bed \
					$CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/$BED_FILE_PREFIX

			# ADD A .bed suffix to all of the now splitted files

				ls $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/$BED_FILE_PREFIX* \
				| awk '{print "mv",$0,$0".bed"}' \
				| bash
			}

	# UNIQUE THE SAMPLE INTO SAMPLE/PROJECT COMBOS AND CREATE A SAMPLE SHEET INTO 300 SAMPLE CHUNKS.

		# awk 'BEGIN {FS=",";OFS="\t"} NR>1 {print $1,$8}' \
		# $SAMPLE_SHEET \
		# 	| sort -k 1,1 -k 2,2 \
		# 	| uniq \
		# 	| split -l 300 -a 4 -d - \
		# 	$CORE_PATH/$PROJECT_MS/TEMP/SPLIT_SS/

		# # # Use the chunked up sample sheets to create gvcf list chunks

		# 	for PROJECT_SAMPLE_LISTS in $(ls $CORE_PATH/$PROJECT_MS/TEMP/SPLIT_SS/*)
		# 		do
		# 			awk 'BEGIN {OFS="/"} {print "'$CORE_PATH'",$1,"GVCF",$2".g.vcf.gz"}' \
		# 				$PROJECT_SAMPLE_LISTS \
		# 				>| $PROJECT_SAMPLE_LISTS.list
		# 	done

	# take all of the project/sample combos in the sample sheet and write a g.vcf file path to a *list file
	# At this point this is just for record keeping...it is being scatterred above
		CREATE_GVCF_LIST ()
		{
			# count how many unique sample id's (with project) are in the sample sheet.
			TOTAL_SAMPLES=(`awk 'BEGIN{FS=","} NR>1{print $1,$8}' $SAMPLE_SHEET \
				| sort \
				| uniq \
				| wc -l`)

			# find all of the gvcf files write all of the full paths to a *samples.gvcf.list file.
			awk 'BEGIN{FS=","} NR>1{print $1,$8}' $SAMPLE_SHEET \
			 | sort \
			 | uniq \
			 | awk 'BEGIN{OFS="/"}{print "ls " "'$CORE_PATH'",$1,"GVCF",$2".g.vcf*"}' \
			 | bash \
			 | egrep -v "idx|tbi" \
			>| $CORE_PATH'/'$PROJECT_MS'/'$TOTAL_SAMPLES'.samples.gvcf.list'

			# STORE THE GVCF LIST FILE PATH AS A VARIABLE
			GVCF_LIST=(`echo $CORE_PATH'/'$PROJECT_MS'/'$TOTAL_SAMPLES'.samples.gvcf.list'`)
		}

	# Run Ben's EnhancedSequencingQCReport which;
	# Generates a QC report for lab specific metrics including Physique Report, Samples Table, Sequencer XML data, Pca and Phoenix.
	# Does not check if samples are dropped.

		RUN_LAB_PREP_METRICS ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N A02-LAB_PREP_METRICS"_"$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PROJECT_MS"-LAB_PREP_METRICS.log" \
			$SCRIPT_DIR/A02_LAB_PREP_METRICS.sh \
				$JAVA_1_8 \
				$LAB_QC_DIR \
				$CORE_PATH \
				$PROJECT_MS \
				$SAMPLE_SHEET
		}

############################################################
##### CALL THE ABOVE FUNCTIONS TO SET-UP JOINT CALLING #####
############################################################

	CREATE_PROJECT_INFO_ARRAY
	# CREATE_CHROMOSOME_LIST
	# FORMAT_AND_SCATTER_BAIT_BED
	# CREATE_GVCF_LIST
	RUN_LAB_PREP_METRICS
	echo sleep 0.1s

#######################################################################
#######################################################################
################# Scatter of Joint Calling ############################
#######################################################################
#######################################################################

	# aggregate all of individual g.vcf into one cohort g.vcf per bed file chunk

		COMBINE_GVCF ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N 'A01_COMBINE_GVCF_'$PROJECT_MS'_'$PGVCF_LIST_NAME'_'$BED_FILE_NAME \
				-o $CORE_PATH/$PROJECT_MS/LOGS/A01_COMBINE_GVCF/"A01_COMBINE_GVCF_"$PGVCF_LIST_NAME"_"$BED_FILE_NAME".log" \
			$SCRIPT_DIR/A01_COMBINE_GVCF.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PGVCF_LIST \
				$PREFIX \
				$BED_FILE_NAME
		}

# for BED_FILE in $(ls $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/BF*bed);
# do
# 	BED_FILE_NAME=$(basename $BED_FILE .bed)
# 		for PGVCF_LIST in $(ls $CORE_PATH/$PROJECT_MS/TEMP/SPLIT_SS/*list)
# 			do
# 				PGVCF_LIST_NAME=$(basename $PGVCF_LIST .list)
# 				COMBINE_GVCF
# 				echo sleep 0.1s
# 		done
# done

#####################################################################

	BUILD_HOLD_ID_GENOTYPE_GVCF ()
	{
		for PROJECT_A in $PROJECT_MS;
		# yeah, so uh, this looks bad, but I just needed a way to set a new project variable that equals the multi-sample project variable.
		do
			GENOTYPE_GVCF_HOLD_ID="-hold_jid "

				for PGVCF_LIST in $(ls $CORE_PATH/$PROJECT_A/TEMP/SPLIT_SS/*list)
					do
						PGVCF_LIST_NAME=$(basename $PGVCF_LIST .list)
						GENOTYPE_GVCF_HOLD_ID=$GENOTYPE_GVCF_HOLD_ID'A01_COMBINE_GVCF_'$PROJECT_A'_'$PGVCF_LIST_NAME'_'$BED_FILE_NAME','
				done
		done
	}

	# genotype the cohort g.vcf chunks

		GENOTYPE_GVCF ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N B01_GENOTYPE_GVCF_$PROJECT_MS'_'$BED_FILE_NAME \
				-o $CORE_PATH/$PROJECT_MS/LOGS/B01_GENOTYPE_GVCF/B01_GENOTYPE_GVCF_$BED_FILE_NAME.log \
			$GENOTYPE_GVCF_HOLD_ID \
			$SCRIPT_DIR/B01_GENOTYPE_GVCF.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX \
				$BED_FILE_NAME
		}

	# add dnsnp ID, genotype summaries, gc percentage, variant class, tandem repeat units and homopolymer runs to genotyped g.vcf chunks.

		VARIANT_ANNOTATOR ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N C$HACK'_'$BED_FILE_NAME \
				-o $CORE_PATH/$PROJECT_MS/LOGS/C01_VARIANT_ANNOTATOR/C01_VARIANT_ANNOTATOR_$BED_FILE_NAME.log \
			-hold_jid B01_GENOTYPE_GVCF_$PROJECT_MS'_'$BED_FILE_NAME \
			$SCRIPT_DIR/C01_VARIANT_ANNOTATOR.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX \
				$BED_FILE_NAME \
				$PROJECT_DBSNP
		}

	# build a string of job names (comma delim) from the variant annotator scatter to store as variable to use as
	# hold_jid for the cat variants gather (it's used in the next section after the for loop below)

		GENERATE_CAT_VARIANTS_HOLD_ID ()
		{
			CAT_VARIANTS_HOLD_ID=$CAT_VARIANTS_HOLD_ID'C'$HACK'_'$BED_FILE_NAME','
		}

	# for each chunk of the original bed file, do combine gvcfs, then genotype gvcfs, then variant annotator
	# then generate a string of all the variant annotator job names submitted

# for BED_FILE in $(ls $CORE_PATH/$PROJECT_MS/TEMP/BED_FILE_SPLIT/BF*bed);
# do
# 	BED_FILE_NAME=$(basename $BED_FILE .bed)
# 	BUILD_HOLD_ID_GENOTYPE_GVCF
# 	GENOTYPE_GVCF
# 	echo sleep 0.1s
# 	VARIANT_ANNOTATOR
# 	echo sleep 0.1s
# 	GENERATE_CAT_VARIANTS_HOLD_ID
# done

#########################################################
#########################################################
##### VCF Gather and  Genotype Refinement Functions #####
#########################################################
#########################################################

	# use cat variants to gather up all of the vcf files above into one big file
	# MIGHT WANT TO LOOK INTO GatherVcfs (Picard) here
	# Other possibility is MergeVcfs (Picard)...GatherVcfs is supposedly used for scatter operations so hopefully more efficient
	# The way that CatVariants is constructed, I think would cause a upper limit to the scatter operation.

		CAT_VARIANTS ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N D01_CAT_VARIANTS_$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_D01_CAT_VARIANTS.log' \
			-hold_jid $CAT_VARIANTS_HOLD_ID \
			$SCRIPT_DIR/D01_CAT_VARIANTS.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX
		}

	# run the snp vqsr model
	# to do: find a better to push out an R version to build the plots...in the end a docker/singularity image would probably best when possible
	# right now, it's buried inside the shell script itself {grrrr}

		VARIANT_RECALIBRATOR_SNV ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N E01_VARIANT_RECALIBRATOR_SNV_$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_E01_VARIANT_RECALIBRATOR_SNV.log' \
			-hold_jid D01_CAT_VARIANTS_$PROJECT_MS \
			$SCRIPT_DIR/E01_VARIANT_RECALIBRATOR_SNV.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$HAPMAP_VCF \
				$OMNI_VCF \
				$ONEKG_SNPS_VCF \
				$DBSNP_138_VCF \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX
		}

	# run the indel vqsr model (concurrently done with the snp model above)
	# to do: find a better to push out an R version to build the plots...in the end a docker/singularity image would probably best when possible
	# right now, it's buried inside the shell script itself {grrrr}

		VARIANT_RECALIBRATOR_INDEL ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N E02_VARIANT_RECALIBRATOR_INDEL_$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_E02_VARIANT_RECALIBRATOR_INDEL.log' \
			-hold_jid D01_CAT_VARIANTS_$PROJECT_MS \
			$SCRIPT_DIR/E02_VARIANT_RECALIBRATOR_INDEL.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$ONEKG_INDELS_VCF \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX
		}

	# apply the snp vqsr model to the full vcf
	# this wait for both the snp and indel models to be done generating before running.

		APPLY_RECALIBRATION_SNV ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N F01_APPLY_RECALIBRATION_SNV_$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_F01_APPLY_RECALIBRATION_SNV.log' \
			-hold_jid E01_VARIANT_RECALIBRATOR_SNV_$PROJECT_MS \
			$SCRIPT_DIR/F01_APPLY_RECALIBRATION_SNV.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX
		}

	# now apply the indel vqsr model to the full vcf file

		APPLY_RECALIBRATION_INDEL ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N G01_APPLY_RECALIBRATION_INDEL_$PROJECT_MS \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_G01_APPLY_RECALIBRATION_INDEL.log' \
			-hold_jid F01_APPLY_RECALIBRATION_SNV_$PROJECT_MS,E02_VARIANT_RECALIBRATOR_INDEL_$PROJECT_MS \
			$SCRIPT_DIR/G01_APPLY_RECALIBRATION_INDEL.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$REF_GENOME \
				$CORE_PATH \
				$PROJECT_MS \
				$PREFIX
		}

# call cat variants and vqsr

	# CAT_VARIANTS
	# echo sleep 0.1s
	# VARIANT_RECALIBRATOR_SNV
	# echo sleep 0.1s
	# VARIANT_RECALIBRATOR_INDEL
	# echo sleep 0.1s
	# APPLY_RECALIBRATION_SNV
	# echo sleep 0.1s
	# APPLY_RECALIBRATION_INDEL
	# echo sleep 0.1s

##################################################
##### ANNOTATE RARE VARIANTS WITH SAMPLE IDS #####
##################################################

	SELECT_RARE_BIALLELIC ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-j y \
		-N H01_SELECT_RARE_BIALLELIC_$PROJECT_MS \
			-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_H01_SELECT_RARE_BIALLELIC.log' \
		-hold_jid G01_APPLY_RECALIBRATION_INDEL_$PROJECT_MS \
		$SCRIPT_DIR/H01_SELECT_RARE_BIALLELIC.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$REF_GENOME \
			$CORE_PATH \
			$PROJECT_MS \
			$PREFIX
	}

	# consider doing this a per chr scatter/gather
	# can scatter if absolutely needed

	ANNOTATE_SELECT_RARE_BIALLELIC ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-j y \
		-N H01A01_ANNOTATE_SELECT_RARE_BIALLELIC_$PROJECT_MS \
			-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_H01A01_ANNOTATE_SELECT_RARE_BIALLELIC.log' \
		-hold_jid H01_SELECT_RARE_BIALLELIC_$PROJECT_MS \
		$SCRIPT_DIR/H01A01_ANNOTATE_SELECT_RARE_BIALLELIC.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$REF_GENOME \
			$CORE_PATH \
			$PROJECT_MS \
			$PREFIX
	}

	SELECT_COMMON_BIALLELIC ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-j y \
		-N H02_SELECT_COMMON_BIALLELIC_$PROJECT_MS \
			-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_H02_SELECT_COMMON_BIALLELIC.log' \
		-hold_jid G01_APPLY_RECALIBRATION_INDEL_$PROJECT_MS \
		$SCRIPT_DIR/H02_SELECT_COMMON_BIALLELIC.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$REF_GENOME \
			$CORE_PATH \
			$PROJECT_MS \
			$PREFIX
	}

	SELECT_MULTIALLELIC ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-j y \
		-N H03_SELECT_MULTIALLELIC_$PROJECT_MS \
			-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_H03_SELECT_MULTIALLELIC.log' \
		-hold_jid G01_APPLY_RECALIBRATION_INDEL_$PROJECT_MS \
		$SCRIPT_DIR/H03_SELECT_MULTIALLELIC.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$REF_GENOME \
			$CORE_PATH \
			$PROJECT_MS \
			$PREFIX
	}

	COMBINE_VARIANTS_VCF ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-j y \
		-N I01_COMBINE_VARIANTS_VCF_$PROJECT_MS \
			-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_I01_COMBINE_VARIANTS_VCF.log' \
		-hold_jid H03_SELECT_MULTIALLELIC_$PROJECT_MS','H02_SELECT_COMMON_BIALLELIC_$PROJECT_MS','H01A01_ANNOTATE_SELECT_RARE_BIALLELIC_$PROJECT_MS \
		$SCRIPT_DIR/I01_COMBINE_VARIANTS_VCF.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$REF_GENOME \
			$CORE_PATH \
			$PROJECT_MS \
			$PREFIX
	}

	# make calls

		# SELECT_RARE_BIALLELIC
		# echo sleep 0.1s
		# ANNOTATE_SELECT_RARE_BIALLELIC
		# echo sleep 0.1s
		# SELECT_COMMON_BIALLELIC
		# echo sleep 0.1s
		# SELECT_MULTIALLELIC
		# echo sleep 0.1s
		# COMBINE_VARIANTS_VCF
		# echo sleep 0.1s

#########################################################
#########################################################
##### VARIANT SUMMARY STATS VCF BREAKOUTS ###############
#########################################################
#########################################################

	#################################################################################################
	### generate separate sample lists for hapmap samples and study samples #########################
	### these are to do breakouts of the refined multi-sample vcf for Hua's variant summary stats ###
	#################################################################################################

		# generate list files by parsing the header of the final ms vcf file
			GENERATE_STUDY_HAPMAP_SAMPLE_LISTS ()
			{
				HAP_MAP_SAMPLE_LIST=(`echo $CORE_PATH'/'$PROJECT_MS'/MULTI_SAMPLE/VARIANT_SUMMARY_STAT_VCF/'$PREFIX'_hapmap_samples.list'`)

				MENDEL_SAMPLE_LIST=(`echo $CORE_PATH'/'$PROJECT_MS'/MULTI_SAMPLE/VARIANT_SUMMARY_STAT_VCF/'$PREFIX'_study_samples.list'`)

				# technically don't have to wait on the gather to happen to do this, but for simplicity sake...
				# if performance becomes an issue then can revisit

					echo \
						qsub \
							-S /bin/bash \
				 			-cwd \
				 			-V \
				 			-q $QUEUE_LIST \
				 			-p $PRIORITY \
				 			-j y \
						-N J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
							-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS.log' \
				 		-hold_jid I01_COMBINE_VARIANTS_VCF_$PROJECT_MS \
						$SCRIPT_DIR/J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS.sh \
							$CORE_PATH \
							$PROJECT_MS \
							$PREFIX
			}

		# select all the snp sites
			SELECT_SNVS_ALL ()
			{
				echo \
				 qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A01_SELECT_SNPS_FOR_ALL_SAMPLES_$PROJECT_MS \
				 	-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A01_SELECT_SNPS_FOR_ALL_SAMPLES.log' \
				 -hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A01_SELECT_ALL_SAMPLES_SNP.sh \
				 	$JAVA_1_8 \
				 	$GATK_DIR \
				 	$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX
			}

		# select only passing snp sites that are polymorphic for the study samples
		# the list are for excluding those samples from the vcf
			SELECT_PASS_STUDY_ONLY_SNP ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A02_SELECT_PASS_STUDY_ONLY_SNP_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A02_SELECT_PASS_STUDY_ONLY_SNP.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A02_SELECT_PASS_STUDY_ONLY_SNP.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX \
				 	$HAP_MAP_SAMPLE_LIST
			}

		# select only passing snp sites that are polymorphic for the hapmap samples
		# the list are for excluding those samples from the vcf
			SELECT_PASS_HAPMAP_ONLY_SNP ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A03_SELECT_PASS_HAPMAP_ONLY_SNP_$PROJECT_MS \
				 	-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A03_SELECT_PASS_HAPMAP_ONLY_SNP.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A03_SELECT_PASS_HAPMAP_ONLY_SNP.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX \
				 	$MENDEL_SAMPLE_LIST
			}

		# select all the indel (and mixed) sites
			SELECT_INDELS_ALL ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A04_SELECT_INDELS_FOR_ALL_SAMPLES_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A04_SELECT_INDELS_FOR_ALL_SAMPLES.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A04_SELECT_ALL_SAMPLES_INDELS.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX
			}

		# select only passing indel/mixed sites that are polymorphic for the study samples
			SELECT_PASS_STUDY_ONLY_INDELS ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A05_SELECT_PASS_STUDY_ONLY_INDEL_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A05_SELECT_PASS_STUDY_ONLY_INDEL.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A05_SELECT_PASS_STUDY_ONLY_INDEL.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX \
				 	$HAP_MAP_SAMPLE_LIST
			}

		# select only passing indel/mixed sites that are polymorphic for the hapmap samples
			SELECT_PASS_HAPMAP_ONLY_INDELS ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A06_SELECT_PASS_HAPMAP_ONLY_INDEL_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A06_SELECT_PASS_HAPMAP_ONLY_INDEL.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A06_SELECT_PASS_HAPMAP_ONLY_INDEL.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
				 	$CORE_PATH \
				 	$PROJECT_MS \
				 	$PREFIX \
				 	$MENDEL_SAMPLE_LIST
			}

		# select all passing snp sites
			SELECT_SNVS_ALL_PASS ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A07_SELECT_SNP_FOR_ALL_SAMPLES_PASS_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A07_SELECT_SNP_FOR_ALL_SAMPLES_PASS.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A07_SELECT_ALL_SAMPLES_SNP_PASS.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
					$CORE_PATH \
					$PROJECT_MS \
					$PREFIX
			}

		# select all passing indel/mixed sites
			SELECT_INDEL_ALL_PASS ()
			{
				echo \
				qsub \
					-S /bin/bash \
			 		-cwd \
			 		-V \
			 		-q $QUEUE_LIST \
			 		-p $PRIORITY \
			 		-j y \
				-N J01A08_SELECT_INDEL_FOR_ALL_SAMPLES_PASS_$PROJECT_MS \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$PREFIX'_J01A08_SELECT_INDEL_FOR_ALL_SAMPLES_PASS.log' \
				-hold_jid J01_GENERATE_STUDY_HAPMAP_SAMPLE_LISTS_$PROJECT_MS \
				$SCRIPT_DIR/J01A08_SELECT_ALL_SAMPLES_INDEL_PASS.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$REF_GENOME \
					$CORE_PATH \
					$PROJECT_MS \
					$PREFIX
			}

# variant summary stat vcf breakouts

	# GENERATE_STUDY_HAPMAP_SAMPLE_LISTS
	# SELECT_SNVS_ALL
	# echo sleep 0.1s
	# SELECT_PASS_STUDY_ONLY_SNP
	# echo sleep 0.1s
	# SELECT_PASS_HAPMAP_ONLY_SNP
	# echo sleep 0.1s
	# SELECT_INDELS_ALL
	# echo sleep 0.1s
	# SELECT_PASS_STUDY_ONLY_INDELS
	# echo sleep 0.1s
	# SELECT_PASS_HAPMAP_ONLY_INDELS
	# echo sleep 0.1s
	# SELECT_SNVS_ALL_PASS
	# echo sleep 0.1s
	# SELECT_INDEL_ALL_PASS
	# echo sleep 0.1s

# #######################################################################
# #######################################################################
# ################### Start of Sample Breakouts #########################
# #######################################################################
# #######################################################################


	# for each unique sample id in the sample sheet grab the bed files, ref genome, project and store as an array

		CREATE_SAMPLE_INFO_ARRAY ()
		{
			SAMPLE_INFO_ARRAY=(`sed 's/\r//g' $SAMPLE_SHEET \
				| awk 'BEGIN{FS=","} NR>1 {print $1,$8,$17,$15,$18,$12,$16}' \
				| sed 's/,/\t/g' \
				| sort -k 8,8 \
				| uniq \
				| awk '$2=="'$SAMPLE'" {print $1,$2,$3,$4,$5,$6,$7}'`)

			PROJECT_SAMPLE=${SAMPLE_INFO_ARRAY[0]}
			SM_TAG=${SAMPLE_INFO_ARRAY[1]}
			TARGET_BED=${SAMPLE_INFO_ARRAY[2]}
			TITV_BED=${SAMPLE_INFO_ARRAY[3]}
			DBSNP=${SAMPLE_INFO_ARRAY[4]} #Not used unless we implement HC_BAM
			SAMPLE_REF_GENOME=${SAMPLE_INFO_ARRAY[5]}
			BAIT_BED=${SAMPLE_INFO_ARRAY[6]}

			UNIQUE_ID_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks
			BARCODE_2D=$(echo $SM_TAG | awk '{split($1,SM_TAG,/[@-]/); print SM_TAG[2]}') # SM_TAG = RIS_ID[@-]BARCODE_2D
		}

	# for each sample make a bunch directories if not already present in the samples defined project directory

		MAKE_PROJ_DIR_TREE ()
		{
			mkdir -p \
			$CORE_PATH/$PROJECT_SAMPLE/{TEMP,LOGS,COMMAND_LINES} \
			$CORE_PATH/$PROJECT_SAMPLE/INDEL/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$PROJECT_SAMPLE/SNV/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$PROJECT_SAMPLE/MIXED/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$PROJECT_SAMPLE/VCF/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$PROJECT_SAMPLE/REPORTS/{TI_TV_MS,CONCORDANCE_MS} \
			$CORE_PATH/$PROJECT_SAMPLE/TEMP/{$SM_TAG"_MS_CONCORDANCE",$SM_TAG"_SCATTER"} \
			$CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG
		}

		SELECT_PASSING_VARIANTS_PER_SAMPLE ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02_SELECT_VARIANTS_FOR_SAMPLE_$SM_TAG".log" \
			-hold_jid I01_COMBINE_VARIANTS_VCF_$PROJECT_MS \
			/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CMG_PIPELINE_UPDATE_ANALYSIS/misc_scripts/J02_SELECT_VARIANTS_FOR_SAMPLE_CAPTURE.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$SAMPLE_REF_GENOME \
				$CORE_PATH \
				$PROJECT_SAMPLE \
				$PROJECT_MS \
				$SM_TAG \
				$PREFIX \
				$BAIT_BED
		}


		PASSING_VARIANTS_ON_TARGET_BY_SAMPLE ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N J02A01_PASSING_VARIANTS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A01_PASSING_VARIANTS_ON_TARGET_BY_SAMPLE_$SAMPLE.log \
			-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
			$SCRIPT_DIR/J02A01_PASSING_VARIANTS_ON_TARGET_BY_SAMPLE.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$SAMPLE_REF_GENOME \
				$CORE_PATH \
				$PROJECT_SAMPLE \
				$SM_TAG \
				$TARGET_BED
		}

			PASSING_SNVS_ON_BAIT_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A02_PASSING_SNVS_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A02_PASSING_SNVS_ON_BAIT_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A02_PASSING_SNVS_ON_BAIT_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG
			}

		# for each sample, make a vcf containing only passing snvs that fall within the on target bed file

			PASSING_SNVS_ON_TARGET_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A03_PASSING_SNVS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A03_PASSING_SNVS_ON_TARGET_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A03_PASSING_SNVS_ON_TARGET_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TARGET_BED
			}

			# for each sample use the passing on target snvs to calculate concordance and het sensitivity to array genotypes.
			# reconfigure using the new concordance tool.
				CONCORDANCE_ON_TARGET_PER_SAMPLE ()
				{
					echo \
					qsub \
						-S /bin/bash \
						-cwd \
						-V \
						-q $QUEUE_LIST \
						-p $PRIORITY \
						-j y \
					-N J02A03-1_CONCORDANCE_ON_TARGET_PER_SAMPLE_$UNIQUE_ID_SM_TAG \
						-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A03-1_CONCORDANCE_ON_TARGET_PER_SAMPLE_$SAMPLE.log \
					-hold_jid J02A03_PASSING_SNVS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					$SCRIPT_DIR/J02A03-1_CONCORDANCE_ON_TARGET_PER_SAMPLE.sh \
						$JAVA_1_8 \
						$CIDRSEQSUITE_7_5_0_DIR \
						$VERACODE_CSV \
						$CORE_PATH \
						$PROJECT_SAMPLE \
						$SM_TAG \
						$TARGET_BED
				}

	##########################################################################
	### grabbing per sample indel only vcf files for on bait and on target ###
	##########################################################################

		# for each sample, make a vcf containing only passing indels

			PASSING_INDELS_ON_BAIT_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A04_PASSING_INDELS_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A04_PASSING_INDELS_ON_BAIT_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A04_PASSING_INDELS_ON_BAIT_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG
			}

		# for each sample, make a vcf containing only passing indels that fall within the on target bed file

			PASSING_INDELS_ON_TARGET_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A05_PASSING_INDELS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A05_PASSING_INDELS_ON_TARGET_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A05_PASSING_INDELS_ON_TARGET_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TARGET_BED
			}

	########################################################
	### grabbing per sample snv only vcf files for ti/tv ###
	########################################################

		# for each sample, make a vcf containing only passing snvs that fall within the on titv bed file

			PASSING_SNVS_TITV_ALL ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A06_PASSING_SNVS_TITV_ALL_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A06_PASSING_SNVS_TITV_ALL_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A06_PASSING_SNVS_TITV_ALL.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TITV_BED
			}

			# for each sample, calculate ti/tv for all passing snvs within the ti/tv bed file

				TITV_ALL ()
				{
					echo \
					qsub \
						-S /bin/bash \
						-cwd \
						-V \
						-q $QUEUE_LIST \
						-p $PRIORITY \
						-j y \
					-N J02A06-1_TITV_ALL_$UNIQUE_ID_SM_TAG \
						-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A06-1_TITV_ALL_$SAMPLE.log \
					-hold_jid J02A06_PASSING_SNVS_TITV_ALL_$UNIQUE_ID_SM_TAG \
					$SCRIPT_DIR/J02A06-1_TITV_ALL.sh \
						$SAMTOOLS_0118_DIR \
						$CORE_PATH \
						$PROJECT_SAMPLE \
						$SM_TAG
				}

		# for each sample, make a vcf containing only passing snvs that fall within the on titv bed file and are in dbsnp129

			PASSING_SNVS_TITV_KNOWN ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A07_PASSING_SNVS_TITV_KNOWN_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A07_PASSING_SNVS_TITV_KNOWN_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A07_PASSING_SNVS_TITV_KNOWN.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$KNOWN_SNPS \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TITV_BED
			}

				# for each sample, calculate ti/tv for all passing snvs within the ti/tv bed file that are in dbsnp129

					TITV_KNOWN ()
					{
						echo \
						qsub \
							-S /bin/bash \
							-cwd \
							-V \
							-q $QUEUE_LIST \
							-p $PRIORITY \
							-j y \
						-N J02A07-1_TITV_KNOWN_$UNIQUE_ID_SM_TAG \
							-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A07-1_TITV_KNOWN_$SAMPLE.log \
						-hold_jid J02A07_PASSING_SNVS_TITV_KNOWN_$UNIQUE_ID_SM_TAG \
						$SCRIPT_DIR/J02A07-1_TITV_KNOWN.sh \
							$SAMTOOLS_0118_DIR \
							$CORE_PATH \
							$PROJECT_SAMPLE \
							$SM_TAG
					}

		# for each sample, make a vcf containing only passing snvs that fall within the on titv bed file and are NOT in dbsnp129

			PASSING_SNVS_TITV_NOVEL ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A08_PASSING_SNVS_TITV_NOVEL_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A08_PASSING_SNVS_TITV_NOVEL_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A08_PASSING_SNVS_TITV_NOVEL.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$KNOWN_SNPS \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TITV_BED
			}

				# for each sample, calculate ti/tv for all passing snvs within the ti/tv bed file that are NOT in dbsnp129

					TITV_NOVEL ()
					{
						echo \
						qsub \
							-S /bin/bash \
							-cwd \
							-V \
							-q $QUEUE_LIST \
							-p $PRIORITY \
							-j y \
						-N J02A08-1_TITV_NOVEL_$UNIQUE_ID_SM_TAG \
							-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A08-1_TITV_NOVEL_$SAMPLE.log \
						-hold_jid J02A08_PASSING_SNVS_TITV_NOVEL_$UNIQUE_ID_SM_TAG \
						$SCRIPT_DIR/J02A08-1_TITV_NOVEL.sh \
							$SAMTOOLS_0118_DIR \
							$CORE_PATH \
							$PROJECT_SAMPLE \
							$SM_TAG
					}

	##########################################################################
	### grabbing per sample indel only vcf files for on bait and on target ###
	##########################################################################

		# for each sample, make a vcf containing only passing mixed

			PASSING_MIXED_ON_BAIT_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A09_PASSING_MIXED_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A09_PASSING_MIXED_ON_BAIT_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A09_PASSING_MIXED_ON_BAIT_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG
			}

		# for each sample, make a vcf containing only passing indels that fall within the on target bed file

			PASSING_MIXED_ON_TARGET_BY_SAMPLE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
					-j y \
				-N J02A10_PASSING_MIXED_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
					-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/J02A10_PASSING_MIXED_ON_TARGET_BY_SAMPLE_$SAMPLE.log \
				-hold_jid J02_SELECT_VARIANTS_FOR_SAMPLE_$UNIQUE_ID_SM_TAG \
				$SCRIPT_DIR/J02A10_PASSING_MIXED_ON_TARGET_BY_SAMPLE.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$SAMPLE_REF_GENOME \
					$CORE_PATH \
					$PROJECT_SAMPLE \
					$SM_TAG \
					$TARGET_BED
			}

	# MAKE A QC REPORT FOR EACH SAMPLE
	# THIS IS CREATING A JOB_ID FOR A SAMPLE WHEN ALL OF THE BREAKOUTs PER SAMPLE IS DONE
	# THIS IS TO MITIGATE CREATING A HOLD ID THAT IS TOO LONG FOR GENERATING THE QC REPORT.
	# ALTHOUGH AT SOME POINT THIS STRING MIGHT END BEING TOO LONG AT SOME POINT.
	# SO QC REPORTS MIGHT HAVE TO END UP BEING DONE OUTSIDE OF THE PIPELINE FOR SOME BIG PROJECTS.
	# yucky, yuck...indenting creates a white space in the hold id which does not work so I have to do this hot mess.
	
		QC_REPORT_PREP ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
				-j y \
			-N Y"_"$BARCODE_2D \
				-o $CORE_PATH/$PROJECT_MS/LOGS/$SM_TAG/$SM_TAG"-QC_REPORT_PREP_QC.log" \
			-hold_jid A02-LAB_PREP_METRICS"_"$PROJECT_MS,\
J02A01_PASSING_VARIANTS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A02_PASSING_SNVS_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A03-1_CONCORDANCE_ON_TARGET_PER_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A04_PASSING_INDELS_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A05_PASSING_INDELS_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A06-1_TITV_ALL_$UNIQUE_ID_SM_TAG,\
J02A07-1_TITV_KNOWN_$UNIQUE_ID_SM_TAG,\
J02A08-1_TITV_NOVEL_$UNIQUE_ID_SM_TAG,\
J02A09_PASSING_MIXED_ON_BAIT_BY_SAMPLE_$UNIQUE_ID_SM_TAG,\
J02A10_PASSING_MIXED_ON_TARGET_BY_SAMPLE_$UNIQUE_ID_SM_TAG \
$SCRIPT_DIR/Y01_QC_REPORT_PREP.sh \
	$SAMTOOLS_DIR \
	$DATAMASH_DIR \
	$CORE_PATH \
	$PROJECT_SAMPLE \
	$SM_TAG \
	$PROJECT_MS \
	$PREFIX
		}

for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq )
do
	CREATE_SAMPLE_INFO_ARRAY
	MAKE_PROJ_DIR_TREE
	# SELECT_PASSING_VARIANTS_PER_SAMPLE
	# echo sleep 0.1s
	PASSING_VARIANTS_ON_TARGET_BY_SAMPLE
	echo sleep 0.1s
	PASSING_SNVS_ON_BAIT_BY_SAMPLE
	echo sleep 0.1s
	PASSING_SNVS_ON_TARGET_BY_SAMPLE
	echo sleep 0.1s
	CONCORDANCE_ON_TARGET_PER_SAMPLE
	echo sleep 0.1s
	PASSING_INDELS_ON_BAIT_BY_SAMPLE
	echo sleep 0.1s
	PASSING_INDELS_ON_TARGET_BY_SAMPLE
	echo sleep 0.1s
	PASSING_SNVS_TITV_ALL
	echo sleep 0.1s
	TITV_ALL
	echo sleep 0.1s
	PASSING_SNVS_TITV_KNOWN
	echo sleep 0.1s
	TITV_KNOWN
	echo sleep 0.1s
	PASSING_SNVS_TITV_NOVEL
	echo sleep 0.1s
	TITV_NOVEL
	echo sleep 0.1s
	PASSING_MIXED_ON_BAIT_BY_SAMPLE
	echo sleep 0.1s
	PASSING_MIXED_ON_TARGET_BY_SAMPLE
	echo sleep 0.1s
	QC_REPORT_PREP
	echo sleep 0.1s
done

##########################################################################
######################End of Functions####################################
##########################################################################

	# Maybe I'll make this a function and throw it into a loop, but today is not that day.
	# I think that i will have to make this a look to handle multiple projects...maybe not
	# but again, today is not that day.

		awk 'BEGIN {FS=","} NR>1 {print $8}' \
		$SAMPLE_SHEET \
			| awk '{split($1,sm_tag,/[@-]/)} {print sm_tag[2]}' \
			| sort -k 1,1 \
			| uniq \
			| $DATAMASH_DIR/datamash \
				-s \
				collapse 1 \
			| awk 'gsub (/,/,",Y_",$1) \
				{print "qsub",\
					"-S /bin/bash",\
					"-cwd",\
					"-V",\
					"-q" , "'$QUEUE_LIST'",\
					"-p" , "'$PRIORITY'",\
					"-j y",\
					"-m","e",\
					"-M","cidr_sequencing_notifications@lists.johnshopkins.edu",\
				"-N" , "Y01-Y01-END_PROJECT_TASKS_" "'$PREFIX'",\
					"-o","'$CORE_PATH'" "/" "'$PROJECT_MS'" "/LOGS/Y01-Y01-" "'$PREFIX'" ".END_PROJECT_TASKS.log",\
				"-hold_jid" , "Y_"$1,\
				"'$SCRIPT_DIR'" "/Y01-Y01_END_PROJECT_TASKS.sh",\
					"'$CORE_PATH'",\
					"'$DATAMASH_DIR'",\
					"'$PROJECT_MS'",\
					"'$PREFIX'",\
					"'$SAMPLE_SHEET'" "\n" "sleep 0.1s"}'	
