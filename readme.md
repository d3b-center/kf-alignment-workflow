# KFDRC Whole Genome Alignment Workflow

![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)


Kids First Data Resource Center Alignment and Haplotype Calling Workflow (bam-to-cram-to-gVCF). This pipeline follows
Broad best practices outlined in [Data pre-processing for variant discovery.](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11165)
It uses bam input and aligns/re-aligns to a bwa-indexed reference fasta, version hg38.  Resultant bam is de-dupped and
base score recalibrated.  Contamination is calculated and a gVCF is created using GATK4 Haplotype caller. Inputs from
this can be used later on for further analysis in joint trio genotyping and subsequent refinement and deNovo variant analysis.

## Basic Info
- pipeline flowchart:
  - [draw.io](https://tinyurl.com/y952jek2)
- tool images: https://hub.docker.com/r/kfdrc/
- dockerfiles: https://github.com/d3b-center/bixtools
- tested with
  - rabix-v1.0.5: https://github.com/rabix/bunny/releases/tag/v1.0.5
  - cwltool: https://github.com/common-workflow-language/cwltool/releases/tag/1.0.20171107133715

## References:
- https://console.cloud.google.com/storage/browser/broad-references/hg38/v0/
- kfdrc bucket: s3://kids-first-seq-data/broad-references/
- cavatica: https://cavatica.sbgenomics.com/u/yuankun/kf-reference/

## Inputs:
```yaml
  input_bam: input.bam
  reference_fasta: Homo_sapiens_assembly38.fasta # For proper bwa functionality, you also need to copy over all bwa index files related to this reference, with suffixes .alt, .amb, .ann, .bwt, .pac, .sa.  These are known as "secondary files" in cwl.
  reference_fai: Homo_sapiens_assembly38.fai
  reference_dict: Homo_sapiens_assembly38.dict
  knownsites:
  - 1000G_omni2.5.hg38.vcf.gz
  - 1000G_phase1.snps.high_confidence.hg38.vcf.gz
  - Homo_sapiens_assembly38.known_indels.vcf.gz
  - Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
  dbsnp_vcf: Homo_sapiens_assembly38.dbsnp138.vcf
  dbsnp_vcf_index: Homo_sapiens_assembly38.dbsnp138.vcf.idx
  wgs_calling_interval_list: wgs_calling_regions.hg38.interval_list
  wgs_coverage_interval_list: wgs_coverage_regions.hg38.interval_list
  wgs_evaluation_interval_list: wgs_evaluation_regions.hg38.interval_list
  contamination_sites_bed: Homo_sapiens_assembly38.contam.bed
  contamination_sites_mu: Homo_sapiens_assembly38.contam.mu
  contamination_sites_ud: Homo_sapiens_assembly38.contam.UD
```
- [sequence_grouping_tsv](examples/sequence_grouping.txt), generated by `bin/CreateSequenceGroupingTSV.py`
- [example-inputs.json](examples/example-inputs.json)

Note, for all vcf files, indexing may be required - a "secondary file" requirement.

![WF Visualized](./kfdrc_alignment_wf.png?raw=true "Workflow diagram")

## Input Agnostic Alignment Workflow
Workflow for the alignment or realignment of input BAMs, PE reads, and/or SE reads; conditionally generate gVCF and metrics.

This workflow is a all-in-one workflow for handling any kind of reads inputs: BAM inputs, PE reads
and mates inputs, SE reads inputs,  or any combination of these. The workflow will naively attempt
to process these depending on what you tell it you have provided. The user informs the workflow of
which inputs to process using three boolean inputs: `run_bam_processing`, `run_pe_reads_processing`,
and `run_se_reads_processing`. Providing `true` values for these as well their corresponding inputs
will result in those inputs being processed.

The second half of the workflow deals with optional gVCF creation and metrics collection.
This workflow is capable of collecting the metrics using the following boolean flags: `run_hs_metrics`,
`run_wgs_metrics`, and `run_agg_metrics`. To run these metrics, additional optional inputs must
also be provided: `wxs_bait_interval_list` and `wxs_target_interval_list` for HsMetrics,
`wgs_coverage_interval_list` for WgsMetrics. To generate the gVCF, set `run_gvcf_processing` to
`true` and provide the following optional files: `dbsnp_vcf`, `contamination_sites_bed`,
`contamination_sites_mu`, `contamination_sites_ud`, `wgs_calling_interval_list`, and
`wgs_evaluation_interval_list`.

### Staging Inputs:
The pipeline is build to handle three distinct input types:
1. BAMs
1. PE Fastqs
1. SE Fastqs

Additionally, the workflow supports these three in any combination. You can have PE Fastqs and BAMs,
PE Fastqs and SE Fastqs, BAMS and PE Fastqs and SE Fastqs, etc. Each of these three classes will be
procsessed and aligned separately and the resulting BWA aligned bams will be merged into a final BAM
before performing steps like BQSR and Metrics collection.

#### BAM Inputs
The BAM processing portion of the pipeline is the simplest when it comes to inputs. You may provide
a single BAM or many BAMs. The input for BAMs is a file list. In Cavatica or other GUI interfaces,
simply select the files you wish to process. For command line interfaces such as cwltool, your input
should look like the following.
```json
{
  ...,
  "run_pe_reads_processing": false,
  "run_se_reads_processing": false,
  "run_bam_processing": true,
  "input_bam_list": [
    {
      "class": "File",
      "location": "/path/to/bam1.bam"
    },
    {
      "class": "File",
      "location": "/path/to/bam2.bam"
    }
  ],
  ...
}
```

#### SE Fastq Inputs
SE fastq processing requires more input to build the jobs correctly. Rather than providing a single
list you must provide two lists: `input_se_reads_list` and `input_se_rgs_list`. The `input_se_reads_list`
is where you put the files and the `input_se_rgs_list` is where you put your desired BAM @RG headers for
each reads file. These two lists are must be ordered and of equal length. By ordered, that means the
first item of the `input_se_rgs_list` will be used when aligning the first item of the `input_se_reads_list`.
IMPORTANT NOTE: When you are entering the rg names, you need to use a second escape `\` to the tab values `\t`
as seen below. When the string value is read in by a tool such as cwltool it will interpret a `\\t` input
as `\t` and a `\t` as the literal `<tab>` value which is not a valid entry for bwa mem.
If you are using Cavatica GUI, however, no extra escape is necessary. The GUI will add an extra
escape to any tab values you enter.

In Cavatica make sure to double check that everything is in the right order when you enter the inputs.
In command line interfaces such as cwltool, your input should look like the following.
```json
{
  ...,
  "run_pe_reads_processing": false,
  "run_se_reads_processing": true,
  "run_bam_processing": false,
  "input_se_reads_list": [
    {
      "class": "File",
      "location": "/path/to/single1.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/single2.fastq"
    }
  ],
  "inputs_se_rgs_list": [
    "@RG\\tID:single1\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name",
    "@RG\\tID:single2\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name"
  ],
  ...
}
```
Take particular note of how the first item in the rgs list is the metadata for the first item in the fastq list.

#### PE Fastq Inputs
PE Fastq processing inputs is exactly like SE Fastq processing but requires you to provide the paired mates
files for your input paired reads. Once again, when using Cavatica make sure your inputs are in the correct
order. In command line interfaces such as cwltool, your input should look like the following.
```json
{
  ...,
  "run_pe_reads_processing": true,
  "run_se_reads_processing": false,
  "run_bam_processing": false,
  "input_pe_reads_list": [
    {
      "class": "File",
      "location": "/path/to/sample1_R1.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample2_R1fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample3_R1.fastq"
    }
  ],
  "input_pe_mates_list": [
    {
      "class": "File",
      "location": "/path/to/sample1_R2.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample2_R2.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample3_R2.fastq"
    }
  ],
  "inputs_pe_rgs_list": [
    "@RG\\tID:sample1\\tLB:library_name\\tPL:ILLUMINA\tSM:sample_name",
    "@RG\\tID:sample2\\tLB:library_name\\tPL:ILLUMINA\tSM:sample_name",
    "@RG\\tID:sample3\\tLB:library_name\\tPL:ILLUMINA\tSM:sample_name"
  ],
  ...
}
```

#### Multiple Input Types
As mentioned above, these three input types can be added in any combination. If you wanted to add
all three your command line input would look like the following.
```json
{
  ...,
  "run_pe_reads_processing": true,
  "run_se_reads_processing": true,
  "run_bam_processing": true,
  "input_bam_list": [
    {
      "class": "File",
      "location": "/path/to/bam1.bam"
    },
    {
      "class": "File",
      "location": "/path/to/bam2.bam"
    }
  ],
  "input_se_reads_list": [
    {
      "class": "File",
      "location": "/path/to/single1.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/single2.fastq"
    }
  ],
  "inputs_se_rgs_list": [
    "@RG\\tID:single1\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name",
    "@RG\\tID:single2\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name"
  ],
  "input_pe_reads_list": [
    {
      "class": "File",
      "location": "/path/to/sample1_R1.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample2_R1fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample3_R1.fastq"
    }
  ],
  "input_pe_mates_list": [
    {
      "class": "File",
      "location": "/path/to/sample1_R2.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample2_R2.fastq"
    },
    {
      "class": "File",
      "location": "/path/to/sample3_R2.fastq"
    }
  ],
  "inputs_pe_rgs_list": [
    "@RG\\tID:sample1\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name",
    "@RG\\tID:sample2\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name",
    "@RG\\tID:sample3\\tLB:library_name\\tPL:ILLUMINA\\tSM:sample_name"
  ],
  ...
}
```

### Example Runtimes:
1. 120 GB WGS BAM with AggMetrics, WgsMetrics, and gVCF creation: 14 hours & $35
1. 120 GB WGS BAM only: 11 hours
1. 4x40 GB WGS FASTQ files with AggMetrics, WgsMetrics, and gVCF creation: 23 hours & $72
1. 4x40 GB WGS FASTQ files only: 18 hours
1. 4x9 GB WXS FASTQ files with AggMetrics and gVCF creation: 4 hours & $9
1. 4x9 GB WXS FASTQ files only: 3 hours

### Caveats:
1. Duplicates are flagged in a process that is connected to bwa mem. The implication of this design
   decision is that duplicates are flagged only on the inputs of that are scattered into bwa.
   Duplicates, therefore, are not being flagged at a library level and, for large BAM and FASTQ inputs,
   duplicates are only being detected within a portion of the read group.

### Tips for running:
1. For the fastq input file lists (PE or SE), make sure the lists are properly ordered. The items in
   the arrays are processed based on their position. These lists are dotproduct scattered. This means
   that the first file in `input_pe_reads_list` is run with the first file in `input_pe_mates_list`
   and the first string in `input_pe_rgs_list`. This also means these arrays must be the same
   length or the workflow will fail.
1. The expected input for the reference_tar is a tar file containing the reference fasta along with its indexes.
   Any deviation from the following will result in a failed run:
```
~ tar tf Homo_sapiens_assembly38.tgz
Homo_sapiens_assembly38.dict
Homo_sapiens_assembly38.fasta
Homo_sapiens_assembly38.fasta.64.alt
Homo_sapiens_assembly38.fasta.64.amb
Homo_sapiens_assembly38.fasta.64.ann
Homo_sapiens_assembly38.fasta.64.bwt
Homo_sapiens_assembly38.fasta.64.pac
Homo_sapiens_assembly38.fasta.64.sa
Homo_sapiens_assembly38.fasta.fai
```
1. Turning off gVCF creation and metrics collection for a minimal successful run.
1. Suggested reference inputs (available from the [Broad Resource Bundle](https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0)):
```yaml
contamination_sites_bed: Homo_sapiens_assembly38.contam.bed
contamination_sites_mu: Homo_sapiens_assembly38.contam.mu
contamination_sites_ud: Homo_sapiens_assembly38.contam.UD
dbsnp_vcf: Homo_sapiens_assembly38.dbsnp138.vcf
reference_tar: Homo_sapiens_assembly38.tgz
knownsites:
  - Homo_sapiens_assembly38.known_indels.vcf.gz
  - Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
  - 1000G_phase1.snps.high_confidence.hg38.vcf.gz
  - 1000G_omni2.5.hg38.vcf.gz
reference_dict: Homo_sapiens_assembly38.dict
```

![WF Visualized](./docs/kfdrc_alignment_wf_cyoa.cwl.png?raw=true "Workflow diagram")
