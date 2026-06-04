# mags_maker

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[[_TOC_]]

## Pipeline overview

**mags_maker** is a Nextflow DSL2 pipeline for generating Metagenome-Assembled Genomes (MAGs) from short-read metagenomic sequencing data. It is based on the [generate_mags](../generate_mags) pipeline with additional assembly options and reporting functionality.

The pipeline runs six stages:

1. **QC and decontamination** — adapter trimming (TrimGalore), human read removal (BMTagger), and per-sample quality reports (FastQC/MultiQC).
2. **Assembly** — metagenomic assembly using metaSPAdes and/or MEGAHIT (default: both).
3. **Binning** — assembled contigs are binned into MAG candidates using multiple binning tools.
4. **Bin refinement** — bin quality is assessed and refined using CheckM1 (default) or CheckM2.
5. **Bin reassembly** (optional) — high-quality bins are reassembled using SPAdes to improve contiguity.
6. **Reporting** — a summary report is generated across all samples.

## Usage

### Quickstart

#### From source code

1. Clone this repository (including submodules):

   ```bash
   git clone --recurse-submodules https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/mags_maker.git
   cd mags_maker
   ```

2. To run with `docker`, use the `-profile docker` option:

   ```bash
   nextflow run main.nf \
       -profile docker \
       --manifest manifest.csv \
       --outdir my_output
   ```

   Other profiles are also supported (`singularity`).  
   :warning: If no profile is specified the pipeline will run with the Sanger HPC-specific configuration.

3. Once the run has finished, clean up intermediate files:

   ```bash
   rm -rf work .nextflow*
   ```

#### Using on the Sanger farm

First load the latest pipeline module:

```bash
module load mags_maker
```

Then run on the command line with `mags_maker <options>`. For instance, to see a help message:

```bash
mags_maker --help
```

Submit to LSF:

```bash
bsub -o output.o -e error.e -q oversubscribed -R "select[mem>4000] rusage[mem=4000]" -M4000 \
    mags_maker \
        --manifest manifest.csv \
        --outdir my_output
```

### Input

#### Manifest (`--manifest`)

A CSV file with the required header `ID,R1,R2`, containing per-sample paths to paired `.fastq.gz` files:

```
ID,R1,R2
sampleA,/path/to/sampleA_1.fastq.gz,/path/to/sampleA_2.fastq.gz
sampleB,/path/to/sampleB_1.fastq.gz,/path/to/sampleB_2.fastq.gz
```

#### Generating a manifest

**Sanger users:** the [manifest_generator](https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/manifest_generator/) tool can generate a compatible `ID,R1,R2` manifest from a directory of FASTQ files or from iRODS.

#### Other input modes

This pipeline supports additional input modes via the `mixed_input` sub-workflow — these can be combined in a single run:

- **iRODS** (Sanger internal) — specify `--studyid`, `--runid`, `--laneid`, and/or `--plexid` on the command line; at least `--studyid` or `--runid` is required. A batch CSV of multiple iRODS searches can be supplied via `--manifest_of_lanes`. Requires an active iRODS session (`iinit`).
- **ENA download** — supply a file of ENA accession IDs via `--manifest_ena`. Set `--accession_type` to `run` (default), `sample`, or `study`.
- **Directory scan** — provide a path to a directory of FASTQ files via `--manifest_from_dir`. Use `--fastq_validation` (`strict`/`relaxed`, default: `strict`) and `--max_depth` (default: `0`) to control discovery.

Run `--help` for the full parameter list.

### Output

Results are written to `--outdir` (default: `./results`):

```
results/
  qc/
    fastqc/                        # FastQC reports (pre- and post-filtering)
    multiqc/                       # MultiQC summary
  assembly/
    <sample_ID>/
      metaspades/                  # metaSPAdes assembly
      megahit/                     # MEGAHIT assembly
  binning/
    <sample_ID>/                   # Bin candidate FASTA files
  bin_refinement/
    <sample_ID>/                   # Refined bins with completeness/contamination metrics
  reassembly/                      # Reassembled bins (when --skip_reassembly false)
    <sample_ID>/
  reports/
    summary_report.csv             # Cross-sample summary
```

### Parameters

**Input options**

| Option       | Type   | Default | Description                                                     |
| ------------ | ------ | ------- | --------------------------------------------------------------- |
| `--manifest` | `path` | `""`    | Input manifest CSV with required header `ID,R1,R2` (mandatory). |

---

**Assembly options**

| Option         | Type      | Default | Description              |
| -------------- | --------- | ------- | ------------------------ |
| `--metaspades` | `boolean` | `true`  | Run metaSPAdes assembly. |
| `--megahit`    | `boolean` | `true`  | Run MEGAHIT assembly.    |

---

**Bin refinement options**

| Option      | Type      | Default | Description                                                                 |
| ----------- | --------- | ------- | --------------------------------------------------------------------------- |
| `--checkm1` | `boolean` | `true`  | Use CheckM1 for bin quality assessment. Set `false` to use CheckM2 instead. |

---

**Pipeline options**

| Option              | Type      | Default    | Description                   |
| ------------------- | --------- | ---------- | ----------------------------- |
| `--qc`              | `string`  | `metawrap` | QC method to use.             |
| `--skip_reassembly` | `boolean` | `false`    | Skip the bin reassembly step. |

---

**Output options**

| Option              | Type      | Default     | Description                          |
| ------------------- | --------- | ----------- | ------------------------------------ |
| `--outdir`          | `path`    | `./results` | Directory where results are written. |
| `--monochrome_logs` | `boolean` | `false`     | Output logs in plain ASCII.          |

See `mags_maker --help` for the full parameter list including QC, assembly, binning, refinement, and reassembly sub-workflow parameters.

### Advanced usage

#### Running with only one assembler

To use only metaSPAdes:

```bash
nextflow run main.nf --manifest manifest.csv --megahit false --outdir my_output
```

To use only MEGAHIT:

```bash
nextflow run main.nf --manifest manifest.csv --metaspades false --outdir my_output
```

#### Skipping reassembly

Bin reassembly is enabled by default. To skip it and save compute time:

```bash
nextflow run main.nf --manifest manifest.csv --skip_reassembly --outdir my_output
```

### Dependencies

All dependencies are containerised in publicly available Docker/Singularity images.

The BMTagger human decontamination step requires a BMTagger database (default: `/data/pam/software/bmtagger` on the Sanger HPC). For external users, build or download a BMTagger index for your host reference.

## Software versions

Key software:

| Software   | Version | Image                                                     |
| ---------- | ------- | --------------------------------------------------------- |
| TrimGalore | 0.4.4   | `quay.io/sangerpathogens/trimgalore:v0.4.4`               |
| BMTagger   | 3.101   | `quay.io/biocontainers/bmtagger:3.101--h470a237_4`        |
| metaSPAdes | 3.15.5  | `quay.io/biocontainers/spades:3.15.5--h95f258a_1`         |
| MEGAHIT    | 1.2.9   | `quay.io/biocontainers/megahit:1.2.9--h5ca1c30_6`         |
| CheckM     | 1.2.4   | `quay.io/biocontainers/checkm-genome:1.2.4--pyhdfd78af_0` |
| CheckM2    | 1.0.2   | `quay.io/biocontainers/checkm2:1.0.2--pyh7cba7a3_0`       |

See `assorted-sub-workflows/mags_maker/*/modules/` for pinned container versions.

## Troubleshooting

- **BMTagger database not found**: ensure the BMTagger database is available at the configured path. On the Sanger HPC the default path is pre-configured.
- **Assembly fails with insufficient memory**: metaSPAdes is memory-intensive. Adjust the resource labels via a custom config or use only MEGAHIT for low-memory runs.
- **Resuming a failed run**: add `-resume` to your command to restart from cached intermediate results.
- For further help, check `.nextflow.log` and the per-process logs in the `work/` directory.

## Issues and Contributions

**GitHub users:** if you find an issue with this pipeline, or would like to suggest an improvement, please log an issue or open a pull request on this repository.

**Sanger users:** if you need internal support, you can raise an issue on the PAM Freshservice portal: https://sanger.freshservice.com/support/catalog/items/426
