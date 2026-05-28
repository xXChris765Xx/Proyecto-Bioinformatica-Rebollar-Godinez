# ==============================================================================
# CONFIGURACIÓN Y VARIABLES GLOBALES
# ==============================================================================
# Definimos las URLs de los archivos de E. coli exactos que usó tu compañero
REF_URL = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
READ1_URL = "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz"
READ2_URL = "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz"

# ==============================================================================
# REGLA PRINCIPAL (TARGET RULE)
# ==============================================================================
# Al terminar la ejecución...
rule all:
    input:
        "reference/GCF_000005845.2_ASM584v2_genomic.fna",
        "data/SRR2584863_1.fastq.gz",
        "data/SRR2584863_2.fastq.gz",
        "results/bam/SRR2584863.sorted.bam",
        "results/fastqc/SRR2584863_1_fastqc.html",
        "results/fastqc/SRR2584863_2_fastqc.html",
        "results/bam/SRR2584863.sorted.bam.bai",
        "results/vcf/SRR2584863.vcf"             

# ==============================================================================
# REGLAS DE OBTENCIÓN DE DATOS
# ==============================================================================

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
        # Incluimos el índice como input para obligar a Snakemake a ejecutar 
        # bwa_index ANTES que bwa_map
        idx="reference/GCF_000005845.2_ASM584v2_genomic.fna.bwt",
        r1="data/SRR2584863_1.fastq.gz",
        r2="data/SRR2584863_2.fastq.gz"
    output:
        "results/bam/SRR2584863.sorted.bam"
    threads: 2 # Podemos decirle a Snakemake que use múltiples núcleos
    shell:
        """
        mkdir -p results/bam
        
        # Mapear con BWA MEM, convertir a BAM y ordenar al vuelo
        bwa mem -t {threads} {input.ref} {input.r1} {input.r2} | \
        samtools sort -@ {threads} -o {output}
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
        "results/bam/{sample}.sorted.bam"
    output:
        "results/bam/{sample}.sorted.bam.bai"
    shell:
        """
        samtools index {input}
        """

# Regla 7: Llamado de variantes utilizando bcftools
rule variant_calling:
    input:
        ref="reference/GCF_000005845.2_ASM584v2_genomic.fna",
        bam="results/bam/{sample}.sorted.bam",
        # Añadimos el índice como input para forzar a que la regla 6 termine primero
        bai="results/bam/{sample}.sorted.bam.bai"
    output:
        "results/vcf/{sample}.vcf"
    shell:
        """
        mkdir -p results/vcf
        
        # 1. mpileup compila los datos de alineamiento (-Ou evita comprimir el paso intermedio)
        # 2. call -mv extrae únicamente las variantes encontradas (-Ov genera formato VCF estándar)
        bcftools mpileup -Ou -f {input.ref} {input.bam} | bcftools call -mv -Ov -o {output}
        """