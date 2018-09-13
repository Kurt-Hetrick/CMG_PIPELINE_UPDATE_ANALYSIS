#!/bin/bash

JAVA_1_7="/isilon/sequencing/Kurt/Programs/Java/jdk1.7.0_25/bin"
CORE_PATH="/isilon/sequencing/Seq_Proj/"
PICARD_DIR="/isilon/sequencing/Kurt/Programs/Picard/picard-tools-1.109"
GATK_DIR="/isilon/sequencing/CIDRSeqSuiteSoftware/gatk/GATK_3/GenomeAnalysisTK-3.1-1"
SAMTOOLS_DIR="/isilon/sequencing/Kurt/Programs/samtools/samtools-0.1.18/"
TABIX_DIR="/isilon/sequencing/Kurt/Programs/TABIX/tabix-0.2.6/"
KEY="/isilon/sequencing/CIDRSeqSuiteSoftware/gatk/GATK_2/lee.watkins_jhmi.edu.key"

REF_GENOME="/isilon/sequencing/GATK_resource_bundle/1.5/b37/human_g1k_v37_decoy.fasta"
EXON_BED="/isilon/sequencing/Seq_Proj/M_Valle_MendelianDisorders_SeqWholeExome_120511_20/BED_Files/TS_TV_BED_File_Agilent_51Mb_v4_S03723314_OnExon_NoCHR_082812.bed"

IN_VCF=$1
PREFIX=$2

#########BREAK OUT INTO DIFFERENT VARIANT TYPES####################

# Break out GATK 3_3-1 into SNV only

$JAVA_1_7/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REF_GENOME \
--disable_auto_index_creation_and_locking_when_reading_rods \
-et NO_ET \
-K $KEY \
-selectType SNP \
--variant $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/MULTI_SAMPLE/$IN_VCF \
-o $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.vcf"

# Break out GATK 3_3-1 into INDEL only

$JAVA_1_7/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REF_GENOME \
--disable_auto_index_creation_and_locking_when_reading_rods \
-et NO_ET \
-K $KEY \
-selectType INDEL \
--variant $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/MULTI_SAMPLE/$IN_VCF \
-o $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.vcf"

################ON EXON BREAKDOWN######################

# Break out GATK 3_3-1 into SNV only

$JAVA_1_7/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REF_GENOME \
--disable_auto_index_creation_and_locking_when_reading_rods \
-et NO_ET \
-K $KEY \
-selectType SNP \
-L $EXON_BED \
--variant $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/MULTI_SAMPLE/$IN_VCF \
-o $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.EXON.vcf"

# Break out GATK 3_3-1 into INDEL only

$JAVA_1_7/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REF_GENOME \
--disable_auto_index_creation_and_locking_when_reading_rods \
-et NO_ET \
-K $KEY \
-selectType INDEL \
-L $EXON_BED \
--variant $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/MULTI_SAMPLE/$IN_VCF \
-o $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.EXON.vcf"

##########################DATASET SUMMARIES SNV ON BAIT#############################

# SNVs, On Bait GATK 3_3-0
# Of those, How many are in dbSNP 138, How Many Pass, How Many are singletons, How Many are doubletons, etc

grep -v "^#" $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.vcf" \
| awk 'BEGIN {OFS="\t"} \
{count++NR} \
{pass+=($7=="PASS")} \
{fail+=($7!="PASS")} \
{pass_dbsnp+=($7=="PASS"&&$3~"rs")} \
{fail_dbsnp+=($7!="PASS"&&$3~"rs")} \
{single+=($8~/^AC=1;/)} \
{pass_single+=($8~/^AC=1;/&&$7=="PASS")} \
{pass_single_dbsnp+=($8~/^AC=1;/&&$7=="PASS"&&$3~"rs")} \
{double+=($8~/^AC=2;/&&$0~"1/1:")} \
{double_pass+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS")} \
{double_pass_dbsnp+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS"&&$3~"rs")} \
{pass_ti+=($5!~","&&$7=="PASS"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_tv+=($5!~","&&$7=="PASS"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_ti+=($5!~","&&$7!="PASS"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_tv+=($5!~","&&$7!="PASS"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_dbsnp_ti+=($5!~","&&$7=="PASS"&&$3~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_dbsnp_tv+=($5!~","&&$7=="PASS"&&$3~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_novel_ti+=($5!~","&&$7=="PASS"&&$3!~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_novel_tv+=($5!~","&&$7=="PASS"&&$3!~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_dbsnp_ti+=($5!~","&&$7!="PASS"&&$3~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_dbsnp_tv+=($5!~","&&$7!="PASS"&&$3~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_novel_ti+=($5!~","&&$7!="PASS"&&$3!~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_novel_tv+=($5!~","&&$7!="PASS"&&$3!~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{hiDeNovo+=($8~"hiConfDeNovo")} \
{hiDeNovoPASS+=($8~"hiConfDeNovo"&&$7=="PASS")} \
{loDeNovo+=($8~"loConfDeNovo")} \
{loDeNovoPASS+=($8~"loConfDeNovo"&&$7=="PASS")} \
{multi+=($5~",")} \
{multiPASS+=($5~","&&$7=="PASS")}
END {print count,pass,(pass/count*100),\
pass_dbsnp,(pass_dbsnp/pass*100),(fail_dbsnp/fail*100),\
single,pass_single,pass_single_dbsnp,\
double,double_pass,double_pass_dbsnp,\
pass_ti/pass_tv,fail_ti/fail_tv,pass_dbsnp_ti/pass_dbsnp_tv,pass_novel_ti/pass_novel_tv,fail_dbsnp_ti/fail_dbsnp_tv,fail_novel_ti/fail_novel_tv,\
hiDeNovo,hiDeNovoPASS,loDeNovo,loDeNovoPASS,\
multi,multiPASS}' \
| awk 'BEGIN {OFS="\t"};{print "CT","CT.PASS","PCT.PASS",\
"PASS.dbSNP138","PASS.PCT.dbSNP138","FAIL.PCT.dbSNP138",\
"SINGLE","PASS.SINGLE","PASS.SINGLE.dbSNP138",\
"DOUBLE","PASS.DOUBLE","PASS.DOUBLE.dbSNP138",\
"PASS.TiTv","FAIL.TiTv","PASS.KNOWN.TiTv","PASS.NOVEL.TiTv","FAIL.KNOWN.TiTv","FAIL.NOVEL.TiTV", \
"hiDeNovo","hiDeNovoPASS","loDeNovo","loDeNovoPASS", \
"MULTI","MULTI_PASS"} \
{print $0}' \
| datamash transpose \
>| $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.OnBait.Summary.txt"

##########################DATASET SUMMARIES SNV ON EXON#############################

# SNVs, On Exon GATK 3_3-0
# Of those, How many are in dbSNP 138, How Many Pass, How Many are singletons, How Many are doubletons, etc

grep -v "^#" $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.EXON.vcf" \
| awk 'BEGIN {OFS="\t"} \
{count++NR} \
{pass+=($7=="PASS")} \
{fail+=($7!="PASS")} \
{pass_dbsnp+=($7=="PASS"&&$3~"rs")} \
{fail_dbsnp+=($7!="PASS"&&$3~"rs")} \
{single+=($8~/^AC=1;/)} \
{pass_single+=($8~/^AC=1;/&&$7=="PASS")} \
{pass_single_dbsnp+=($8~/^AC=1;/&&$7=="PASS"&&$3~"rs")} \
{double+=($8~/^AC=2;/&&$0~"1/1:")} \
{double_pass+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS")} \
{double_pass_dbsnp+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS"&&$3~"rs")} \
{pass_ti+=($5!~","&&$7=="PASS"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_tv+=($5!~","&&$7=="PASS"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_ti+=($5!~","&&$7!="PASS"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_tv+=($5!~","&&$7!="PASS"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_dbsnp_ti+=($5!~","&&$7=="PASS"&&$3~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_dbsnp_tv+=($5!~","&&$7=="PASS"&&$3~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_novel_ti+=($5!~","&&$7=="PASS"&&$3!~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{pass_novel_tv+=($5!~","&&$7=="PASS"&&$3!~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_dbsnp_ti+=($5!~","&&$7!="PASS"&&$3~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_dbsnp_tv+=($5!~","&&$7!="PASS"&&$3~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_novel_ti+=($5!~","&&$7!="PASS"&&$3!~"rs"&&$4$5!~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{fail_novel_tv+=($5!~","&&$7!="PASS"&&$3!~"rs"&&$4$5~/AC|AT|CA|CG|GC|GT|TA|TG/)} \
{hiDeNovo+=($8~"hiConfDeNovo")} \
{hiDeNovoPASS+=($8~"hiConfDeNovo"&&$7=="PASS")} \
{loDeNovo+=($8~"loConfDeNovo")} \
{loDeNovoPASS+=($8~"loConfDeNovo"&&$7=="PASS")} \
{multi+=($5~",")} \
{multiPASS+=($5~","&&$7=="PASS")}
END {print count,pass,(pass/count*100),\
pass_dbsnp,(pass_dbsnp/pass*100),(fail_dbsnp/fail*100),\
single,pass_single,pass_single_dbsnp,\
double,double_pass,double_pass_dbsnp,\
pass_ti/pass_tv,fail_ti/fail_tv,pass_dbsnp_ti/pass_dbsnp_tv,pass_novel_ti/pass_novel_tv,fail_dbsnp_ti/fail_dbsnp_tv,fail_novel_ti/fail_novel_tv,\
hiDeNovo,hiDeNovoPASS,loDeNovo,loDeNovoPASS,\
multi,multiPASS}' \
| awk 'BEGIN {OFS="\t"};{print "CT","CT.PASS","PCT.PASS",\
"PASS.dbSNP138","PASS.PCT.dbSNP138","FAIL.PCT.dbSNP138",\
"SINGLE","PASS.SINGLE","PASS.SINGLE.dbSNP138",\
"DOUBLE","PASS.DOUBLE","PASS.DOUBLE.dbSNP138",\
"PASS.TiTv","FAIL.TiTv","PASS.KNOWN.TiTv","PASS.NOVEL.TiTv","FAIL.KNOWN.TiTv","FAIL.NOVEL.TiTV", \
"hiDeNovo","hiDeNovoPASS","loDeNovo","loDeNovoPASS", \
"MULTI","MULTI_PASS"} \
{print $0}' \
| datamash transpose \
>| $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".SNV.OnExon.Summary.txt"

############################DATASET SUMMARIES INDEL ON BAIT#############################
# 
# # Indel summary GATK 3-3-1
# 

grep -v "^#" $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.vcf" \
| awk 'BEGIN {OFS="\t"} \
{count++NR} \
{pass+=($7=="PASS")} \
{fail+=($7!="PASS")} \
{pass_dbsnp+=($7=="PASS"&&$3~"rs")} \
{fail_dbsnp+=($7!="PASS"&&$3~"rs")} \
{single+=($8~/^AC=1;/)} \
{pass_single+=($8~/^AC=1;/&&$7=="PASS")} \
{pass_single_dbsnp+=($8~/^AC=1;/&&$7=="PASS"&&$3~"rs")} \
{double+=($8~/^AC=2;/&&$0~"1/1:")} \
{double_pass+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS")} \
{double_pass_dbsnp+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS"&&$3~"rs")} \
{big_i+=(length($5)-length($4))>10} \
{big_i_nm+=(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$5!~","} \
{big_i_nm_pass_dbsnp+=(length($5)-length($4))>10&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{big_i_nm_single+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_single_pass+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"} \
{big_i_nm_single_pass_dbsnp+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_i_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"} \
{big_i_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_d+=(length($5)-length($4))<-10} \
{big_d_nm+=(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$5!~","} \
{big_d_nm_pass_dbsnp+=(length($5)-length($4))<-10&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{big_d_nm_single+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_single_pass+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"} \
{big_d_nm_single_pass_dbsnp+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_d_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"} \
{big_d_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{small_i+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)} \
{small_i_nm+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_pass_dbsnp+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_i_nm_single+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_single_pass+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_single_pass_dbsnp+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_i_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)} \
{small_d_nm+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_pass_dbsnp+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d_nm_single+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_single_pass+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_single_pass_dbsnp+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{hiDeNovo+=($8~"hiConfDeNovo")} \
{hiDeNovoPASS+=($8~"hiConfDeNovo"&&$7=="PASS")} \
{big_i_hiDeNovo+=(length($5)-length($4))>10&&$8~"hiConfDeNovo"} \
{big_i_hiDeNovo_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{big_d_hiDeNovo+=(length($5)-length($4))<-10&&$8~"hiConfDeNovo"} \
{big_d_hiDeNovo_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{small_i_hiDeNovo+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$8~"hiConfDeNovo"} \
{small_i_hiDeNovo_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{small_d_hiDeNovo+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$8~"hiConfDeNovo"} \
{small_d_hiDeNovo_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{loDeNovo+=($8~"loConfDeNovo")} \
{loDeNovoPASS+=($8~"loConfDeNovo"&&$7=="PASS")} \
{big_i_loDeNovo+=(length($5)-length($4))>10&&$8~"loConfDeNovo"} \
{big_i_loDeNovo_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$8~"loConfDeNovo"} \
{big_d_loDeNovo+=(length($5)-length($4))<-10&&$8~"loConfDeNovo"} \
{big_d_loDeNovo_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$8~"loConfDeNovo"} \
{small_i_loDeNovo+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$8~"loConfDeNovo"} \
{small_i_loDeNovo_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$8~"loConfDeNovo"} \
{small_d_loDeNovo+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$8~"loConfDeNovo"} \
{small_d_loDeNovo_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$8~"loConfDeNovo"} \
{multi+=($5~",")} \
{multiPASS+=($5~","&&$7=="PASS")} \
END {print count,pass,(pass/count*100),\
pass_dbsnp,(pass_dbsnp/pass*100),(fail_dbsnp/fail*100),\
single,pass_single,pass_single_dbsnp,\
double,double_pass,double_pass_dbsnp,\
big_i,big_i_nm,big_i_nm_pass,big_i_nm_pass_dbsnp,\
big_i_nm_single,big_i_nm_single_pass,big_i_nm_single_pass_dbsnp,\
big_i_nm_double,big_i_nm_double_pass,big_i_nm_double_pass_dbsnp,\
big_d,big_d_nm,big_d_nm_pass,big_d_nm_pass_dbsnp,\
big_d_nm_single,big_d_nm_single_pass,big_d_nm_single_pass_dbsnp,\
big_d_nm_double,big_d_nm_double_pass,big_d_nm_double_pass_dbsnp,\
(big_i_nm_pass/big_d_nm_pass),\
small_i,small_i_nm,small_i_nm_pass,small_i_nm_pass_dbsnp,\
small_i_nm_single,small_i_nm_single_pass,small_i_nm_single_pass_dbsnp,\
small_i_nm_double,small_i_nm_double_pass,small_i_nm_double_pass_dbsnp,\
small_d,small_d_nm,small_d_nm_pass,small_d_nm_pass_dbsnp,\
small_d_nm_single,small_d_nm_single_pass,small_d_nm_single_pass_dbsnp,\
small_d_nm_double,small_d_nm_double_pass,small_d_nm_double_pass_dbsnp,\
(small_i_nm_pass/small_d_nm_pass),\
hiDeNovo,hiDeNovoPASS,\
big_i_hiDeNovo,big_i_hiDeNovo_pass,big_d_hiDeNovo,big_d_hiDeNovo_pass,\
small_i_hiDeNovo,small_i_hiDeNovo_pass,small_d_hiDeNovo,small_d_hiDeNovo_pass,\
loDeNovo,loDeNovoPASS,\
big_i_loDeNovo,big_i_loDeNovo_pass,big_d_loDeNovo,big_d_loDeNovo_pass,\
small_i_loDeNovo,small_i_loDeNovo_pass,small_d_loDeNovo,small_d_loDeNovo_pass,
multi,multiPASS}' \
| awk 'BEGIN {OFS="\t"};{print "CT","CT.PASS","PCT.PASS",\
"PASS.dbSNP138","PASS.PCT.dbSNP138","FAIL.PCT.dbSNP138",\
"SINGLE","PASS.SINGLE","PASS.SINGLE.dbSNP138",\
"DOUBLE","PASS.DOUBLE","PASS.DOUBLE.dbSNP138",\
"INS.GT.10","INS.GT.10.NOT.MULTI","INS.GT.10.NOT.MULTI.PASS","INS.GT.10.NOT.MULTI.PASS.DBSNP138",\
"INS.GT.10.NOT.MULTI.SINGLE","INS.GT.10.NOT.MULTI.SINGLE.PASS","INS.GT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"INS.GT.10.NOT.MULTI.DOUBLE","INS.GT.10.NOT.MULTI.DOUBLE.PASS","INS.GT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"DEL.GT.10","DEL.GT.10.NOT.MULTI","DEL.GT.10.NOT.MULTI.PASS","DEL.GT.10.NOT.MULTI.PASS.DBSNP138",\
"DEL.GT.10.NOT.MULTI.SINGLE","DEL.GT.10.NOT.MULTI.SINGLE.PASS","DEL.GT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"DEL.GT.10.NOT.MULTI.DOUBLE","DEL.GT.10.NOT.MULTI.DOUBLE.PASS","DEL.GT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"I_D.GT.10.RATIO",\
"INS.LT.10","INS.LT.10.NOT.MULTI","INS.LT.10.NOT.MULTI.PASS","INS.LT.10.NOT.MULTI.PASS.DBSNP138",\
"INS.LT.10.NOT.MULTI.SINGLE","INS.LT.10.NOT.MULTI.SINGLE.PASS","INS.LT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"INS.LT.10.NOT.MULTI.DOUBLE","INS.LT.10.NOT.MULTI.DOUBLE.PASS","INS.LT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"DEL.LT.10","DEL.LT.10.NOT.MULTI","DEL.LT.10.NOT.MULTI.PASS","DEL.LT.10.NOT.MULTI.PASS.DBSNP138",\
"DEL.LT.10.NOT.MULTI.SINGLE","DEL.LT.10.NOT.MULTI.SINGLE.PASS","DEL.LT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"DEL.LT.10.NOT.MULTI.DOUBLE","DEL.LT.10.NOT.MULTI.DOUBLE.PASS","DEL.LT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"I_D.LT.10.RATIO",\
"hiDeNovo","hiDeNovo.PASS",\
"INS.GT.10.hiDeNovo","INS.GT.10.hiDeNovo.PASS","DEL.GT.10.hiDeNovo","DEL.GT.10.hiDeNovo.PASS",\
"INS.LT.10.hiDeNovo","INS.LT.10.hiDeNovo.PASS","DEL.LT.10.hiDeNovo","DEL.LT.10.hiDeNovo.PASS",\
"loDeNovo","loDeNovo.PASS",\
"INS.GT.10.loDeNovo","INS.GT.10.loDeNovo.PASS","DEL.GT.10.loDeNovo","DEL.GT.10.loDeNovo.PASS",\
"INS.LT.10.loDeNovo","INS.LT.10.loDeNovo.PASS","DEL.LT.10.loDeNovo","DEL.LT.10.loDeNovo.PASS",\
"MULTI","MULTI_PASS"} \
{print $0}' \
| datamash transpose \
>| $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.OnBait.Summary.txt"

############################DATASET SUMMARIES INDEL ON EXON#############################

# INDEL summary GATK 3.3-0

grep -v "^#" $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.EXON.vcf" \
| awk 'BEGIN {OFS="\t"} \
{count++NR} \
{pass+=($7=="PASS")} \
{fail+=($7!="PASS")} \
{pass_dbsnp+=($7=="PASS"&&$3~"rs")} \
{fail_dbsnp+=($7!="PASS"&&$3~"rs")} \
{single+=($8~/^AC=1;/)} \
{pass_single+=($8~/^AC=1;/&&$7=="PASS")} \
{pass_single_dbsnp+=($8~/^AC=1;/&&$7=="PASS"&&$3~"rs")} \
{double+=($8~/^AC=2;/&&$0~"1/1:")} \
{double_pass+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS")} \
{double_pass_dbsnp+=($8~/^AC=2;/&&$0~"1/1:"&&$7=="PASS"&&$3~"rs")} \
{big_i+=(length($5)-length($4))>10} \
{big_i_nm+=(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$5!~","} \
{big_i_nm_pass_dbsnp+=(length($5)-length($4))>10&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{big_i_nm_single+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_single_pass+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"} \
{big_i_nm_single_pass_dbsnp+=$8~/^AC=1;/&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_i_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","} \
{big_i_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"} \
{big_i_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))>10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_d+=(length($5)-length($4))<-10} \
{big_d_nm+=(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$5!~","} \
{big_d_nm_pass_dbsnp+=(length($5)-length($4))<-10&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{big_d_nm_single+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_single_pass+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"} \
{big_d_nm_single_pass_dbsnp+=$8~/^AC=1;/&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{big_d_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","} \
{big_d_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"} \
{big_d_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&(length($5)-length($4))<-10&&$5!~","&&$7=="PASS"&&$3~"rs"} \
{small_i+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)} \
{small_i_nm+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_pass_dbsnp+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_i_nm_single+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_single_pass+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_single_pass_dbsnp+=$8~/^AC=1;/&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_i_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$5!~","} \
{small_i_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","} \
{small_i_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)} \
{small_d_nm+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_pass_dbsnp+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d_nm_single+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_single_pass+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_single_pass_dbsnp+=$8~/^AC=1;/&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{small_d_nm_double+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$5!~","} \
{small_d_nm_double_pass+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","} \
{small_d_nm_double_pass_dbsnp+=$8~/^AC=2;/&&$0~"1/1:"&&((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$5!~","&&$3~"rs"} \
{hiDeNovo+=($8~"hiConfDeNovo")} \
{hiDeNovoPASS+=($8~"hiConfDeNovo"&&$7=="PASS")} \
{big_i_hiDeNovo+=(length($5)-length($4))>10&&$8~"hiConfDeNovo"} \
{big_i_hiDeNovo_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{big_d_hiDeNovo+=(length($5)-length($4))<-10&&$8~"hiConfDeNovo"} \
{big_d_hiDeNovo_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{small_i_hiDeNovo+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$8~"hiConfDeNovo"} \
{small_i_hiDeNovo_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{small_d_hiDeNovo+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$8~"hiConfDeNovo"} \
{small_d_hiDeNovo_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$8~"hiConfDeNovo"} \
{loDeNovo+=($8~"loConfDeNovo")} \
{loDeNovoPASS+=($8~"loConfDeNovo"&&$7=="PASS")} \
{big_i_loDeNovo+=(length($5)-length($4))>10&&$8~"loConfDeNovo"} \
{big_i_loDeNovo_pass+=(length($5)-length($4))>10&&$7=="PASS"&&$8~"loConfDeNovo"} \
{big_d_loDeNovo+=(length($5)-length($4))<-10&&$8~"loConfDeNovo"} \
{big_d_loDeNovo_pass+=(length($5)-length($4))<-10&&$7=="PASS"&&$8~"loConfDeNovo"} \
{small_i_loDeNovo+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$8~"loConfDeNovo"} \
{small_i_loDeNovo_pass+=((length($5)-length($4))<=10&&(length($5)-length($4))>0)&&$7=="PASS"&&$8~"loConfDeNovo"} \
{small_d_loDeNovo+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$8~"loConfDeNovo"} \
{small_d_loDeNovo_pass+=((length($5)-length($4))>=-10&&(length($5)-length($4))<0)&&$7=="PASS"&&$8~"loConfDeNovo"} \
{multi+=($5~",")} \
{multiPASS+=($5~","&&$7=="PASS")} \
END {print count,pass,(pass/count*100),\
pass_dbsnp,(pass_dbsnp/pass*100),(fail_dbsnp/fail*100),\
single,pass_single,pass_single_dbsnp,\
double,double_pass,double_pass_dbsnp,\
big_i,big_i_nm,big_i_nm_pass,big_i_nm_pass_dbsnp,\
big_i_nm_single,big_i_nm_single_pass,big_i_nm_single_pass_dbsnp,\
big_i_nm_double,big_i_nm_double_pass,big_i_nm_double_pass_dbsnp,\
big_d,big_d_nm,big_d_nm_pass,big_d_nm_pass_dbsnp,\
big_d_nm_single,big_d_nm_single_pass,big_d_nm_single_pass_dbsnp,\
big_d_nm_double,big_d_nm_double_pass,big_d_nm_double_pass_dbsnp,\
(big_i_nm_pass/big_d_nm_pass),\
small_i,small_i_nm,small_i_nm_pass,small_i_nm_pass_dbsnp,\
small_i_nm_single,small_i_nm_single_pass,small_i_nm_single_pass_dbsnp,\
small_i_nm_double,small_i_nm_double_pass,small_i_nm_double_pass_dbsnp,\
small_d,small_d_nm,small_d_nm_pass,small_d_nm_pass_dbsnp,\
small_d_nm_single,small_d_nm_single_pass,small_d_nm_single_pass_dbsnp,\
small_d_nm_double,small_d_nm_double_pass,small_d_nm_double_pass_dbsnp,\
(small_i_nm_pass/small_d_nm_pass),\
hiDeNovo,hiDeNovoPASS,\
big_i_hiDeNovo,big_i_hiDeNovo_pass,big_d_hiDeNovo,big_d_hiDeNovo_pass,\
small_i_hiDeNovo,small_i_hiDeNovo_pass,small_d_hiDeNovo,small_d_hiDeNovo_pass,\
loDeNovo,loDeNovoPASS,\
big_i_loDeNovo,big_i_loDeNovo_pass,big_d_loDeNovo,big_d_loDeNovo_pass,\
small_i_loDeNovo,small_i_loDeNovo_pass,small_d_loDeNovo,small_d_loDeNovo_pass,
multi,multiPASS}' \
| awk 'BEGIN {OFS="\t"};{print "CT","CT.PASS","PCT.PASS",\
"PASS.dbSNP138","PASS.PCT.dbSNP138","FAIL.PCT.dbSNP138",\
"SINGLE","PASS.SINGLE","PASS.SINGLE.dbSNP138",\
"DOUBLE","PASS.DOUBLE","PASS.DOUBLE.dbSNP138",\
"INS.GT.10","INS.GT.10.NOT.MULTI","INS.GT.10.NOT.MULTI.PASS","INS.GT.10.NOT.MULTI.PASS.DBSNP138",\
"INS.GT.10.NOT.MULTI.SINGLE","INS.GT.10.NOT.MULTI.SINGLE.PASS","INS.GT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"INS.GT.10.NOT.MULTI.DOUBLE","INS.GT.10.NOT.MULTI.DOUBLE.PASS","INS.GT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"DEL.GT.10","DEL.GT.10.NOT.MULTI","DEL.GT.10.NOT.MULTI.PASS","DEL.GT.10.NOT.MULTI.PASS.DBSNP138",\
"DEL.GT.10.NOT.MULTI.SINGLE","DEL.GT.10.NOT.MULTI.SINGLE.PASS","DEL.GT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"DEL.GT.10.NOT.MULTI.DOUBLE","DEL.GT.10.NOT.MULTI.DOUBLE.PASS","DEL.GT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"I_D.GT.10.RATIO",\
"INS.LT.10","INS.LT.10.NOT.MULTI","INS.LT.10.NOT.MULTI.PASS","INS.LT.10.NOT.MULTI.PASS.DBSNP138",\
"INS.LT.10.NOT.MULTI.SINGLE","INS.LT.10.NOT.MULTI.SINGLE.PASS","INS.LT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"INS.LT.10.NOT.MULTI.DOUBLE","INS.LT.10.NOT.MULTI.DOUBLE.PASS","INS.LT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"DEL.LT.10","DEL.LT.10.NOT.MULTI","DEL.LT.10.NOT.MULTI.PASS","DEL.LT.10.NOT.MULTI.PASS.DBSNP138",\
"DEL.LT.10.NOT.MULTI.SINGLE","DEL.LT.10.NOT.MULTI.SINGLE.PASS","DEL.LT.10.NOT.MULTI.SINGLE.PASS.DBSNP138",\
"DEL.LT.10.NOT.MULTI.DOUBLE","DEL.LT.10.NOT.MULTI.DOUBLE.PASS","DEL.LT.10.NOT.MULTI.DOUBLE.PASS.DBSNP138",\
"I_D.LT.10.RATIO",\
"hiDeNovo","hiDeNovo.PASS",\
"INS.GT.10.hiDeNovo","INS.GT.10.hiDeNovo.PASS","DEL.GT.10.hiDeNovo","DEL.GT.10.hiDeNovo.PASS",\
"INS.LT.10.hiDeNovo","INS.LT.10.hiDeNovo.PASS","DEL.LT.10.hiDeNovo","DEL.LT.10.hiDeNovo.PASS",\
"loDeNovo","loDeNovo.PASS",\
"INS.GT.10.loDeNovo","INS.GT.10.loDeNovo.PASS","DEL.GT.10.loDeNovo","DEL.GT.10.loDeNovo.PASS",\
"INS.LT.10.loDeNovo","INS.LT.10.loDeNovo.PASS","DEL.LT.10.loDeNovo","DEL.LT.10.loDeNovo.PASS",\
"MULTI","MULTI_PASS"} \
{print $0}' \
| datamash transpose \
>| $CORE_PATH/M_Valle_MendelianDisorders_SeqWholeExome_120511_GATK_3_3-0/KURT_ANALYSIS/$PREFIX".INDEL.OnExon.Summary.txt"

