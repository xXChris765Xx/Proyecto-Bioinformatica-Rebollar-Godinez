# IMAGEN BASE
FROM condaforge/miniforge3:latest

WORKDIR /app
COPY environment.yaml .

# INSTALACIÓN DE DEPENDENCIAS
RUN mamba env update -n base -f environment.yaml -y && mamba clean -afy

COPY Snakefile .

CMD ["snakemake", "-p", "--cores", "2"]