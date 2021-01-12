cwlVersion: v1.0
class: Workflow
id: kfdrc_qc_wf
doc: |-
  # KFDRC QC Workflow
  Workflow for calculating QC metrics and determining QC Pass or Fail

  ![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)

  The workflow runs [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/),
  on fastq files or bam files. The workflow then reads the raw data generated by
  fastqc and the qc statuses determined by fastqc and determines if the sample
  passes QC overall.

requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement

inputs:
  sequences: {type: 'File[]', doc: "set of sequences being run can be either fastqs or bams"}
  return_raw_data: {type: boolean?, doc: "TRUE: return zipped raw data folder or FALSE: only return summary HTML"}
  ram: {type: ['null', int], default: 2, doc: "In GB"}
  max_cpu: {type: ['null', int], default: 8, doc: "Maximum number of CPUs to request"}
  fastqc_params: {type: 'File?', doc: "fastqc parameter file to use"}

outputs:
  fastqc_summary: {type: 'File[]', outputSource: fastqc/output_summaries}
  fastqc_data: {type: 'File[]', outputSource: fastqc/data_folders}
  qc_metrics_file: {type: 'File[]', outputSource: calculate_extra_qc/metrics_file}

steps:
  fastqc:
    run: ../tools/fastqc.cwl
    in:
      sequences: sequences
      return_raw_data:
        valueFrom: ${return Boolean(true)}
      ram: ram
      max_cpu: max_cpu
      fastqc_params: fastqc_params
    out: [output_summaries, data_folders]

  calculate_extra_qc:
    run: ../tools/calculate_extra_qc.cwl
    in:
      fastqc_data: fastqc/data_folders
    scatter: fastqc_data
    out: [metrics_file]
