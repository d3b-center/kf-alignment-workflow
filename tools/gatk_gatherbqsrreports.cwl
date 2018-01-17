cwlVersion: v1.0
class: CommandLineTool
id: gatk_gatherbqsrreports
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.beta.1'
baseCommand: [/gatk-launch, GatherBQSRReports]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      --javaOptions "-Xms3G"
      -O GatherBqsrReports.recal_data.csv
inputs:
  input_brsq_reports:
    type:
      type: array
      items: File
      inputBinding:
        prefix: -I
        separate: true
outputs:
  - id: output
    type: File
    outputBinding:
      glob: '*.csv'
