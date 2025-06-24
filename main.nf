

workflow {
    references = Channel.fromPath(params.references)
    bams = Channel.fromPath("${params.bamdir}/*.bam").collect().toList()

    references
    | combine(bams)
    | Align
}

process Align {
    container 'public.ecr.aws/o5l3p3e4/scalerna:2025-04-11-191914'

    input: tuple path(ref), path(bams)
    output: path("Solo.out")

    script:
    """
    STAR \
        --runThreadN ${task.cpus}  \\
        --genomeDir ${ref} \\
        --soloType CB_UMI_Simple \\
        --soloBarcodeReadLength 0 \\
        --soloCBwhitelist None \\
        --soloCBtype String \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMattributes NH HI nM AS GX GN gx gn sF \\
        --outSAMunmapped Within \\
        --outSJtype None \\
        --soloCellReadStats Standard \\
        --soloStrand Forward \\
        --soloFeatures GeneFull_Ex50pAS \\
        --soloMultiMappers PropUnique \\
        --readFilesIn ${bams.join(",")}	\\
        --readFilesType SAM SE \\
        --readFilesCommand samtools view \\
        --soloInputSAMattrBarcodeSeq CB UM \\
        --soloCellFilter None \\
        --outFilterMultimapNmax 6
    pigz -p ${task.cpus} Solo.out/GeneFull_Ex50pAS/raw/UniqueAndMult-PropUnique.mtx
    pigz -p ${task.cpus} Solo.out/GeneFull_Ex50pAS/raw/barcodes.tsv
    pigz -p ${task.cpus} Solo.out/GeneFull_Ex50pAS/raw/features.tsv
    """
}