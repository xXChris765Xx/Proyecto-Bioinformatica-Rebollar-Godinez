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
        "data/SRR2584863_2.fastq.gz"

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