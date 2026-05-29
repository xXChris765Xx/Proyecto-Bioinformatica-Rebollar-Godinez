# WGS Bioinformatics Pipeline - E. coli

Este repositorio contiene un *pipeline* automatizado para el análisis de Secuenciación de Genoma Completo (WGS) de *E. coli*, desarrollado con **Snakemake**. El flujo abarca desde la descarga automática de datos crudos hasta el llamado de variantes genéticas.

Basado en el flujo de trabajo del [ECA Bioinformatics Handbook](https://eriqande.github.io/eca-bioinf-handbook/example-wgs-flow.html).

## 🚀 Métodos de Ejecución

Para garantizar la máxima compatibilidad, este proyecto ofrece dos arquitecturas de despliegue. Puedes elegir la que mejor se adapte a tu entorno:

1. **Método A (Recomendado):** Despliegue en contenedores usando Docker (Asegura reproducibilidad absoluta).
2. **Método B:** Ejecución local nativa usando WSL/Linux y Mamba.

---

## 🐳 Método A: Ejecución Aislada (Docker)

Esta es la forma más directa de ejecutar el *pipeline* sin preocuparte por dependencias locales o variables de entorno.

**Prerrequisitos:**
* Docker Desktop instalado y corriendo.

**Ejecución con un solo comando:**
Desde la raíz del proyecto, ejecuta:
```bash
docker compose up --build
```

Docker construirá el entorno basado en `condaforge/miniforge3`, instalará las dependencias de `environment.yaml` y ejecutará Snakemake automáticamente. Gracias a la configuración de volúmenes en `docker-compose.yml`, todos los resultados se sincronizarán y guardarán en el directorio local.

---

## 💻 Método B: Ejecución Local Nativa (WSL / Linux)

Si prefieres ejecutar las herramientas directamente en tu máquina host, sigue estos pasos.

### 1. Prerrequisitos del Sistema

Este proyecto está diseñado para ejecutarse en entornos tipo Unix. Si utilizas Windows, es **estrictamente necesario** contar con [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) con una distribución como Ubuntu.

Se requiere **Mamba** (o Conda) para la gestión del entorno bioinformático. Si no lo tienes, puedes instalar Miniforge ejecutando:

```bash
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
bash Miniforge3-Linux-x86_64.sh
```

### 2. Configuración del Entorno

Clona este repositorio, accede a la carpeta principal y crea el entorno virtual que contiene herramientas como `bwa`, `samtools`, `bcftools` y `fastqc`:

```bash
mamba env create -f environment.yaml
mamba activate wgs_pipeline
```

### 3. Ejecución del Pipeline

El `Snakefile` descargará los datos de referencia (Genoma de *E. coli*) y los *reads* de secuenciación de manera automática.

Para ver un resumen de las tareas a ejecutar (Dry-Run):

```bash
snakemake -np
```

Para ejecutar el pipeline completo:

```bash
snakemake -p --cores 2
```

*(Puedes ajustar el número de `--cores` dependiendo de la capacidad de tu procesador).*

---

## 📂 Estructura de Resultados

Una vez finalizada la ejecución (sin importar el método elegido), el proyecto generará automáticamente las siguientes carpetas dinámicas:

* `data/`: Archivos FASTQ crudos descargados automáticamente desde el SRA.
* `reference/`: Genoma de referencia en formato FASTA y sus índices para mapeo (BWA).
* `results/bam/`: Archivos de alineamiento binarios, ordenados y deduplicados (.bam).
* `results/fastqc/`: Reportes de control de calidad en HTML de las secuencias originales.
* `results/vcf/`: Archivo VCF final con las variantes genéticas identificadas.

