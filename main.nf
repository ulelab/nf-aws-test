
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                    } from './modules/nf-core/fastqc'
include { HISAT2_ALIGN              } from './modules/nf-core/hisat2/align'
include { HISAT2_BUILD              } from './modules/nf-core/hisat2/build'
include { HISAT2_EXTRACTSPLICESITES } from './modules/nf-core/hisat2/extractSpliceSites'
include { SALMON_INDEX              } from './modules/nf-core/salmon/index'
include { SALMON_QUANT              } from './modules/nf-core/salmon/quant'
include { GUNZIP as GUNZIP_GTF      } from './modules/nf-core/gunzip/main' 
include { UNTAR  as UNTAR_INDEX     } from './modules/nf-core/untar/main'

def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id           = row.sample
    meta.strandedness = row.strandedness

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!row.fastq_1) {
        error "Error: fastq_1 is empty for sample ${row.sample}"
    }

    if (!row.fastq_2) {
        // Single-end read
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
        meta.single_end = true
    } else {
        // Paired-end read
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
        meta.single_end = false
    }
    return fastq_meta
}

workflow {
    ch_gtf = Channel.fromPath(params.gtf).map { [ [:], it ] }
    ch_hisat2_index = Channel.fromPath(params.hisat2_index).map { [ [:], it ] } 
    ch_salmon_index = Channel.fromPath(params.salmon_index).map { [ [:], it ] } 
    ch_transcript_fasta = Channel.fromPath(params.transcript_fasta).map { [ [:], it ] } 

    channel.fromPath(params.input)
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { ch_fastq }

    FASTQC (
        ch_fastq
    )

    if (params.gtf.endsWith('.gz')) {
        ch_gtf = GUNZIP_GTF ( ch_gtf ).gunzip
    }
    HISAT2_EXTRACTSPLICESITES (
        ch_gtf
    )

    if (params.hisat2_index.endsWith('.tar.gz')) {
        ch_hisat2_index = UNTAR_INDEX ( ch_hisat2_index ).untar.first()
    }

    HISAT2_ALIGN (
        ch_fastq,
        ch_hisat2_index,
        HISAT2_EXTRACTSPLICESITES.out.txt.first()
    )

    SALMON_INDEX (
        params.transcript_fasta,
        params.fasta
    )

    SALMON_QUANT (
        ch_fastq,
        SALMON_INDEX.out.index,
        params.gtf,
        params.transcript_fasta,
        false,
        ''
    )

}