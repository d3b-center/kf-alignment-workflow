cwlVersion: v1.0
class: CommandLineTool
id: picard_collectrawwgsmetrics
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/picard:2.15.0'
baseCommand: [ java, -Xms2G, -jar, /picard.jar, CollectRawWgsMetrics]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      INPUT=$(inputs.input_bam.path)
      VALIDATION_STRINGENCY=SILENT
      REFERENCE_SEQUENCE=$(inputs.reference.path)
      INCLUDE_BQ_HISTOGRAM=true
      INTERVALS=$(inputs.intervals.path)
      OUTPUT=$(inputs.input_bam.nameroot).raw_wgs_metrics
      USE_FAST_ALGORITHM=true
      READ_LENGTH=250
inputs:
  input_bam:
    type: File
    secondaryFiles:
      - ^.bai
  reference:
    type: File
    secondaryFiles:
      - .fai
  intervals:
    type: File
outputs:
  - id: output
    type: File
    outputBinding:
      glob: '*_metrics'
