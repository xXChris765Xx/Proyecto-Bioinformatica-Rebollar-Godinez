
# WGS Bioinformatics Pipeline - E. coli

Este repositorio contiene un pipeline automatizado para el análisis de Secuenciación de Genoma Completo (WGS) de *E. coli*, desarrollado con **Snakemake**. El flujo abarca desde la descarga automática de datos crudos hasta el llamado de variantes genéticas.

Basado en el flujo de trabajo del [ECA Bioinformatics Handbook](https://eriqande.github.io/eca-bioinf-handbook/example-wgs-flow.html).

## 🛠️ Prerrequisitos del Sistema

Este proyecto está diseñado para ejecutarse en entornos tipo Unix. Si utilizas Windows, es **estrictamente necesario** contar con [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) con una distribución como Ubuntu.

Además, se requiere **Mamba** (o Conda) para la gestión del entorno y las dependencias bioinformáticas. 

### Instalación de Mamba (Miniforge) en WSL/Linux
Si no tienes Mamba instalado, puedes configurarlo rápidamente ejecutando:
```bash
wget "[https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh](https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh)"
bash Miniforge3-Linux-x86_64.sh
```


## 🚀 Configuración e Instalación

Después de descargar o clonar el repositorio, accede a la carpeta principal y ejecuta lo siguiente:


1. **Crear el entorno de desarrollo:**
El archivo `environment.yaml` contiene todas las herramientas necesarias (`snakemake`, `bwa`, `samtools`, `bcftools`, `fastqc`). Para crear el entorno, ejecuta:
```bash
mamba env create -f environment.yaml
```


2. **Activar el entorno:**
```bash
mamba activate wgs_pipeline
```



## ⚙️ Ejecución del Pipeline

El `Snakefile` está configurado para manejar la descarga de los datos de referencia (Genoma de *E. coli*) y los *reads* de secuenciación de manera automática.

**Para ver un resumen de las tareas a ejecutar (Dry-Run):**

```bash
snakemake -np
```

**Para ejecutar el pipeline completo:**

```bash
snakemake -p --cores 2
```

*(Puedes ajustar el número de `--cores` dependiendo de la capacidad de tu procesador).*

## 📂 Estructura de Resultados

Una vez finalizada la ejecución, el proyecto generará las siguientes carpetas dinámicas:

* `data/`: Archivos FASTQ crudos descargados automáticamente.
* `reference/`: Genoma de referencia en formato FASTA y sus índices (BWA).
* `results/bam/`: Archivos de alineamiento binarios y ordenados (.bam).
* `results/fastqc/`: Reportes de calidad en HTML de las secuencias originales.
* `results/vcf/`: Archivo VCF final con las variantes genéticas identificadas.
