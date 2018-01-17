cwlVersion: v1.0
class: CommandLineTool
id: picard_validatesamfile
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/picard:2.8.3'
baseCommand: [ java, -Xms2G, -jar, /picard.jar, ValidateSamFile]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      INPUT=$(inputs.input_bam.path)
      OUTPUT=$(inputs.input_bam.nameroot).cram.validation_report
      REFERENCE_SEQUENCE=$(inputs.reference.path)
      MAX_OUTPUT=1000000000
      IGNORE=MISSING_TAG_NM
      MODE=VERBOSE 
      IS_BISULFITE_SEQUENCED=false
inputs:
  input_bam:
    type: File
    secondaryFiles:
      - .crai
  reference:
    type: File
    secondaryFiles:
      - ^.dict
      - .fai
outputs:
  - id: output
    type: File
    outputBinding:
      glob: '*.validation_report'
