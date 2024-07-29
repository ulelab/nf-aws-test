# nf-aws-test
A short pipeline to test nf AWS batch performance

Requires Nextflow >=23.04.0
Can be run using docker or singularity

Run with the test profile to try it out:
`nextflow run main.nf -profile test,docker`

Samples can be provided in a samplesheet.csv with four columns:
sample,fastq_1,fastq_2,strandedness

Strandedness can be: forward, reverse, unstranded.
Fastq_2 is left empty for single end experiments.
