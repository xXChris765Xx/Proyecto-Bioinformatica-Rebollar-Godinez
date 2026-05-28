# ==============================================================================
# CONFIGURACIÓN Y VARIABLES GLOBALES
# ==============================================================================
# URLs de los archivos de E. coli
REF_URL = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
READ1_URL = "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz"
READ2_URL = "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz"

# ==============================================================================
# REGLA PRINCIPAL (TARGET RULE)
# ==============================================================================
# Al terminar la ejecución...
rule all:
    input:
        # "reference/GCF_000005845.2_ASM584v2_genomic.fna",
        # "data/SRR2584863_1.fastq.gz",
        # "data/SRR2584863_2.fastq.gz",
        # "results/bam/SRR2584863.sorted.bam",
        # "results/fastqc/SRR2584863_1_fastqc.html",
        # "results/fastqc/SRR2584863_2_fastqc.html",
        # "results/bam/SRR2584863.dedup.bam.bai",       
        # "results/vcf/SRR2584863.filtered.vcf",
        # "results/bam/SRR2584863.sorted.bam.bai",
        # "results/vcf/SRR2584863.vcf" 
        # 1. Los reportes de calidad (Ramas muertas, no van a ningún otro paso)
        "results/fastqc/SRR2584863_1_fastqc.html",
        "results/fastqc/SRR2584863_2_fastqc.html",
        
        # 2. El índice del BAM final sin duplicados (Útil para visualizar en IGV)
        "results/bam/SRR2584863.dedup.bam.bai",
        
        # 3. El archivo final de variantes ya filtrado y limpio
        "results/vcf/SRR2584863.filtered.vcf"         

# ==============================================================================
# REGLAS DE OBTENCIÓN DE DATOS
# ==============================================================================

# Regla Intermedia: Limpiar los reads crudos
rule trimmomatic:
    input:
        r1="data/{sample}_1.fastq.gz",
        r2="data/{sample}_2.fastq.gz"
    output:
        r1_paired="data/trimmed/{sample}_1.paired.fastq.gz",
        r1_unpaired="data/trimmed/{sample}_1.unpaired.fastq.gz",
        r2_paired="data/trimmed/{sample}_2.paired.fastq.gz",
        r2_unpaired="data/trimmed/{sample}_2.unpaired.fastq.gz"
    shell:
        """
        mkdir -p data/trimmed
        # Corta bases de baja calidad al inicio/fin y usa una ventana deslizante
        trimmomatic PE -phred33 \
            {input.r1} {input.r2} \
            {output.r1_paired} {output.r1_unpaired} \
            {output.r2_paired} {output.r2_unpaired} \
            LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
        """

# Regla 1: Descargar el genoma de referencia y descomprimirlo (E. coli exacto)
rule get_reference:
    output:
        "reference/GCF_000005845.2_ASM584v2_genomic.fna"
    shell:
        """
        mkdir -p reference
        wget -qO - {REF_URL} | gunzip -c > {output}
        """

# Regla 2: Descargar los reads (lecturas de secuenciación)
rule get_reads:
    output:
        r1="data/SRR2584863_1.fastq.gz",
        r2="data/SRR2584863_2.fastq.gz"
    shell:
        """
        mkdir -p data
        wget -qO {output.r1} {READ1_URL}
        wget -qO {output.r2} {READ2_URL}
        """
# ==============================================================================
# REGLAS DE ALINEAMIENTO (MAPPING)
# ==============================================================================

# ------ NOTA -------
# En lugar de guardar un archivo temporal gigantesco en formato SAM (texto plano) 
# y luego leerlo de nuevo para convertirlo a BAM (binario) y ordenarlo, conectamos 
# la salida de bwa directamente a la entrada de samtools.

# Regla 3: Indexar el genoma de referencia
rule bwa_index:
    input:
        "reference/GCF_000005845.2_ASM584v2_genomic.fna"
    output:
        # BWA genera múltiples archivos de índice. Con rastrear uno de ellos 
        # (como el .bwt) Snakemake sabrá cuándo el proceso ha terminado.
        "reference/GCF_000005845.2_ASM584v2_genomic.fna.bwt"
    shell:
        """
        bwa index {input}
        """

# Regla 4: Mapear las lecturas contra el genoma y ordenar el BAM resultante
rule bwa_map:
    input:
        ref="reference/GCF_000005845.2_ASM584v2_genomic.fna",
        idx="reference/GCF_000005845.2_ASM584v2_genomic.fna.bwt",
        r1="data/trimmed/{sample}_1.paired.fastq.gz",
        r2="data/trimmed/{sample}_2.paired.fastq.gz"
    output:
        "results/bam/{sample}.sorted.bam"
    threads: 2
    shell:
        """
        mkdir -p results/bam
        
        # Agregamos la bandera -R para inyectar el Read Group automáticamente
        bwa mem -t {threads} \
            -R "@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            {input.ref} {input.r1} {input.r2} | \
        samtools sort -@ {threads} -o {output}
        """


# Regla Intermedia: Eliminar duplicados de PCR
# Regla Intermedia: Eliminar duplicados de PCR
rule mark_duplicates:
    input:
        "results/bam/{sample}.sorted.bam"
    output:
        bam="results/bam/{sample}.dedup.bam",
        metrics="results/bam/{sample}.metrics.txt"
    shell:
        """
        picard MarkDuplicates \
            I={input} \
            O={output.bam} \
            M={output.metrics} \
            REMOVE_DUPLICATES=true
        """


# ==============================================================================
# REGLAS DE CONTROL DE CALIDAD
# ==============================================================================

# Regla 5: Control de calidad de los reads crudos
rule fastqc:
    input:
        # FastQC analizará los archivos FASTQ que descargamos
        "data/{sample}.fastq.gz"
    output:
        # Genera un HTML interactivo y un ZIP con los datos
        html="results/fastqc/{sample}_fastqc.html",
        zip="results/fastqc/{sample}_fastqc.zip"
    shell:
        """
        mkdir -p results/fastqc
        # El comando fastqc requiere que le especifiquemos el directorio de salida
        fastqc {input} -o results/fastqc/
        """

# ==============================================================================
# REGLAS DE VARIANTES (VARIANT CALLING)
# ==============================================================================

# Regla 6: Generar el índice para el archivo binario BAM
rule samtools_index:
    input:
        "results/bam/{sample}.dedup.bam"
    output:
        "results/bam/{sample}.dedup.bam.bai"
    shell:
        """
        samtools index {input}
        """

# Regla 7: Llamado de variantes utilizando bcftools
rule variant_calling:
    input:
        ref="reference/GCF_000005845.2_ASM584v2_genomic.fna",
        bam="results/bam/{sample}.dedup.bam",
        bai="results/bam/{sample}.dedup.bam.bai"
    output:
        "results/vcf/{sample}.vcf"
    shell:
        """
        mkdir -p results/vcf
        bcftools mpileup -Ou -f {input.ref} {input.bam} | bcftools call -mv -Ov -o {output}
        """
# Regla 8: Filtrar variantes de baja calidad
rule filter_variants:
    input:
        "results/vcf/{sample}.vcf"
    output:
        "results/vcf/{sample}.filtered.vcf"
    shell:
        """
        # Excluimos (-e) las variantes con calidad menor a 20
        bcftools filter -e 'QUAL<20' {input} > {output}
        """