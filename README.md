ANALYSIS RESULTS, SCRIPTS, PLANS FOR UPDATING CMG EXOME PIPELINE
=======

_SUMMER OF 2018_

## PRIMARY GOALS, FEATURES ADDED.

* create cram file with 4 bin base call Q score (like GSP wgs pipeline)
	* duplicate molecule marking in accordance with GSP wgs pipeline

* upgrade gatk from 3.3 to 3.7 for variant analysis
	* _cram file generation uses gatk 4+ plus picard 2.17_
	* automatic removal of foreign DNA during GVCF creation (reads with both ends soft-clipped).
	* better handling (removal of?) pipeline crashes due to too many alleles.
	* better VQSR stability

* automatic passing of verifybamID freemix results to haplotype caller for contamination correction.

* vcf files are bgzip and tabix (compressed) in pipeline

* allow handling of samples with multiple libraries without going through separate pipeline instance

* more qc metrics before joint calling

	* indel summary results.
	* mixed variant summary results.
	* gender checks using seq data
	* chromosomal anomaly checks using seq data
	* oxidation, deamination, capture bias metrics
	* theoretical het sensitivity
	* more accurate coverage metrics (more indicative of what will be used for analysis, old pipeline overestimated)
	* didn't properly account for overlapping reads
	* cram file for haplotype caller variant candidates (generated during gvcf creation)
	* het/hom ratio
	* insertion/deletion ratio
	* and more...
	* qc reports done for submission batches as well as the entire study done every submission.

## UNEXPECTED CHALLENGES ENCOUNTERED.

* cannot create gvcf files specific to capture product b/c either combinegvcfs or genotypegvcfs crash

	* had to create gvcf files with union of capture products super bait file


## ANALYSIS PLANS

1. RECALL RATES FOR CANDIDATE/PUTATIVE VARIANTS.
* By tranche
	* ~~GATK best practice~~
		* given what I saw for the CF grant, it looks like best practices now matches what we are using for CMG (99.9% for both snps and indels)
	* CIDR CMG cut-off
	* PAST VQSR CUT-OFF (i.e. fail)
	* MISSING

			* **SNP CANDIDATE LOCI:**
				* _NEW PIPELINE: ALL LOCI ARE PRESENT AND PASS THE 99.9% CUT-OFF._
				* _OLD PIPELINE: 2 LOCI ARE NO LONGER EMITTED, BUT THE OTHER 179 PASS THE 99.9% CUT-OFF_
				
			* **INDEL CANDIDATE LOCI:**
				* _NEW PIPELINE: ALL LOCI ARE PRESENT AND PASS TEH 99.9% CUT-OFF._

2. BY CAPTURE PRODUCT

During the course of the 6+ Year study, the capture product has changed.
~~GVCF files are only generated for the SUPER BAIT file for the capture performed per individual (not both, not for all reads).~~
	
* **this is no longer feasible**

* ~~reasoning is that reads that are way off what is a possible capture would be enriched for false positives and can negatively impact vqsr for sites that are actually part of another capture (or create false positives).~~

* candidate/putative variants

	* **There are 215 unique variant records**
		* **181 SNPS**
		* **~~34 INDELS~~**
			* **THERE ARE ACTUALLY 30 CANDIDATE INDEL LOCI**
				* 1 IS A DUPLICATE (THE REPORT FOR ONE FAMILY HAD A DIFFERENT END POSITION, BUT IT IS ACTUALLY THE SAME AS ANOTHER FAMILY VARIANT)
				* 1 IS A FALSE POSITIVE
				* 2 ARE FROM A BUG IN UNIFIED GENOTYPER
				* _ALSO 2 ARE MULTI-ALLELIC_
					* MANUALLY CONFIRMED

	* _only in superbait file for product_
		* CLINICAL EXOME CAPTURES ALL OF THEM
		* AGILENT VERSION 4 CAPTURES 212 OF THEM (MISSES 3 SNPS)

	* _only in target+75bp pad_
		* CLINICAL EXOME MISSES ONE SNP
		* AGILENT VERSION 4 CAPTURE HAS NO DIFFERENCE WITH THE SUPER BAIT BED FILE (MISSES 3 SNPS)

	* _only in target NO PADDING_
		* CLINICAL EXOME MISSES 15 SNPS
		* AGILENT VERSION 4 CAPTURES MISSES 5 SNPS (2 MORE THAN WHAT'S MISSED IN THE BAIT SUPER BED FILE)

**Sample count is 2536 (entire call set includes hapmap controls with technical duplicates)**

* _Agilent_ClinicalExome_S06588914=1,075_
* _Agilent_51Mb_v4_S03723314=1,461_


3. UPDATED COUNT OF CANDIDATE VARIANT CHROMOSOME COUNT.

* what is the count based off of phenodb versus what is the count the joint called vcf.

4. ~~GROSS METRICS (not really a priority since I've done everything at the per sample level. no real plans to do this)

* cohort ti/tv
* bait counts
* snp counts
* indel counts
* mixed counts~~

5. Things that I've done in the past that I probably will not prioritize.

* technical duplicate reproducibility
* mendelian inheritance
* de novo counts
