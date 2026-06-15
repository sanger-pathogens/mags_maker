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

![workflow diagram](./assets/mags_maker.svg)

## Usage

### Quickstart

#### From source code

1. Clone this repository (including submodules):

   ```bash
   git clone --recurse-submodules <repo-url>
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

3. Once the run has finished successfully and you have inspected the output, clean up intermediate files. The `work/` directory and `.nextflow.log` are useful for troubleshooting — do not delete them until you are satisfied the outputs are correct:

   ```bash
   rm -rf work .nextflow*
   ```

   Alternatively, use `nextflow clean` for more fine-grained control over which runs and intermediate files are removed.

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

:warning: Note that we recommend running batches of 100 samples or fewer through this pipeline to avoid transient IO errors.

#### Manifest (`--manifest`)

A CSV file with the required header `ID,R1,R2`, containing per-sample paths to paired `.fastq.gz` files:

```
ID,R1,R2
sampleA,/path/to/sampleA_1.fastq.gz,/path/to/sampleA_2.fastq.gz
sampleB,/path/to/sampleB_1.fastq.gz,/path/to/sampleB_2.fastq.gz
```

**Sanger users:** the [manifest_generator](https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/manifest_generator/) tool can generate a compatible `ID,R1,R2` manifest from FASTQ files on disk.

#### Other input modes

This pipeline supports additional input modes via the `mixed_input` sub-workflow — these can be combined in a single run:

- **iRODS** (Sanger internal) — specify `--studyid`, `--runid`, `--laneid`, and/or `--plexid` on the command line; at least `--studyid` or `--runid` is required. A batch CSV of multiple iRODS searches can be supplied via `--manifest_of_lanes`. Requires an active iRODS session (`iinit`).
- **ENA download** — supply a file of ENA accession IDs via `--manifest_ena`. Set `--accession_type` to `run` (default), `sample`, or `study`.
- **Directory scan** — provide a path to a directory of FASTQ files via `--manifest_from_dir`. Use `--fastq_validation` (`strict`/`relaxed`, default: `strict`) and `--max_depth` (default: `0`) to control discovery.

Run `--help` for the full parameter list (specifically the section "Sequencing reads input parameters") or see the [mixed_input documentation](./assorted-sub-workflows/mixed_input/README.md) for more information.

#### BMTagger database

BMTagger removes contaminant host reads from metagenomics datasets during QC with `metawrap` (default). It requires a reference database.
The default is set for the human T2T reference on the Sanger HPC, please adjust if you prefer a different reference or are an external user. Find instructions for making a BMTagger reference database in the tool's documentation: https://ftp.ncbi.nlm.nih.gov/pub/agarwala/bmtagger/README.bmtagger.txt

### Output

Results are written to `--outdir` (default: `./results`):

```
results/
  metawrap_qc/
    cleaned_reads/
      <sample_ID>_clean_1.fastq.gz   # Host-depleted, adapter-trimmed reads
      <sample_ID>_clean_2.fastq.gz
    read_removal_statistics.csv      # Per-sample read removal statistics
  host_reads/                        # Only when --publish_host_reads is set
    <sample_ID>_host_1.fastq.gz
    <sample_ID>_host_2.fastq.gz
  <sample_ID>/
    quast/
      <sample_ID>_assembly_stats/    # QUAST assembly quality report
    checkm1/                         # CheckM1 bin quality summary (when --checkm1 true, default)
      <sample_ID>_<bin>checkm_summary.tsv
    checkm2/                         # CheckM2 bin quality report (when --checkm1 false)
      <sample_ID>_<bin>_checkm2_report.tsv
    <bin>.fasta                      # Final bins and per-sample CheckM report
    <sample_ID>_report.txt
  bin_merging/
    <sample_ID>_merge.log            # Bin merging log
    <sample_ID>_best_bins.stats      # Best-bin selection statistics
  final_summary.tsv                  # Cross-sample summary of all bins
```

Please note that although multiple binning tools run, not all bins generated by all tools are output as the final results. First all bins passing `--min_completeness` and `--max_contamination` are scored on completeness and contamination (scoring aligns with MIMAG standards, penalising contamination five times more than incompleteness). The highest scoring version of each bin is selected as 'best', in the case of multiple highest scoring bins, N50 is used as a decider for the 'best' bin. Only the best bins are published to `<outdir>/<sample_ID>`.

### Parameters

**Input/Output options**

| Option       | Type   | Default     | Description                                                    |
| ------------ | ------ | ----------- | -------------------------------------------------------------- |
| `--manifest` | `path` | `""`        | Input manifest CSV with required header `ID,R1,R2` (required). |
| `--outdir`   | `path` | `./results` | Directory where results are written.                           |

---

**Quality Control options**

| Option                | Type      | Default                       | Description                                                       |
| --------------------- | --------- | ----------------------------- | ----------------------------------------------------------------- |
| `--qc`                | `string`  | `metawrap`                    | Run QC with `metawrap` or supply `skip`.                          |
| `--bmtagger_db`       | `path`    | `/data/pam/software/bmtagger` | Path to directory containing BMTagger database.                   |
| `--bmtagger_host`     | `path`    | `T2T-CHM13v2.0`               | Reference genome version used for host read filtering.            |
| `--publish_host_data` | `boolean` | `false`                       | Publish the reads determined to originate from the host organism. |

---

**Assembly and Re-assembly options**

| Option                    | Type        | Default       | Description                                                                                                |
| ------------------------- | ----------- | ------------- | ---------------------------------------------------------------------------------------------------------- |
| `--fastspades`            | `boolean`   | `false`       | Run SPAdes assembly module only.                                                                           |
| `--metaspades`            | `boolean`   | `true`        | Run metaSPAdes assembly.                                                                                   |
| `--megahit`               | `boolean`   | `true`        | Run MEGAHIT assembly.                                                                                      |
| `--megahit_deterministic` | `boolean`   | `false`       | Run MEGAHIT assembly deterministically, (see [Determinism](#determinism)).                                                          |
| `--assembly_stats`        | `boolean`   | `false`       | Generate assembly statistics.                                                                              |
| `--output_transposed`     | `boolean`   | `false`       | Output transposed QUAST reports.                                                                           |
| `--lock_phred`            | `boolean`   | `false` | Set PHRED quality offset to 33 for sra-lite and other read formats lacking quality scores (SPAdes option). |
| `--skip_reassembly`       | `boolean`   | `false`       | Skip the bin reassembly step.                                                                              |
| `--strict_max`            | `int`       | `2`           | Strict bin mismatch threshold.                                                                             |
| `--permissive_max`        | `int`       | `5`           | Permissive bin mismatch threshold.                                                                         |
| `--min_completeness`      | `float` | `50`          | Minimum completeness threshold (%).                                                                        |
| `--max_contamination`     | `float` | `5`           | Maximum contamination threshold (%).                                                                       |

---

**Bin refinement options**

| Option         | Type      | Default                                             | Description                                                                 |
| -------------- | --------- | --------------------------------------------------- | --------------------------------------------------------------------------- |
| `--checkm1`    | `boolean` | `true`                                              | Use CheckM1 for bin quality assessment. Set `false` to use CheckM2 instead. |
| `--checkm2_db` | `path`    | `/data/pam/software/checkm2_db/uniref100.KO.1.dmnd` | Path to CheckM2 database (required if `--checkm1 false`).                   |

---

**Binning options**

| Option                 | Type      | Default | Description                                                                                                                                               |
| ---------------------- | --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--keep_unbinned`      | `boolean` | `false` | Keep unbinned contigs.                                                                                                                                    |
| `--maxbin2_min_contig` | `int`     | `1000`  | Minimum threshold for contig size (kb) for MaxBin2. The lowest accepted value is 500.                                                                     |
| `--concoct_min_contig` | `int`     | `1000`  | Minimum threshold for contig size (kb) for CONCOCT. The lowest accepted value is 500.                                                                     |
| `--metabat_min_contig` | `int`     | `1500`  | Minimum threshold for contig size (kb) for metaBAT. The lowest accepted value is 1500.                                                                    |
| `--metabat1`           | `boolean` | `false` | Run metaBAT1 as opposed to default metaBAT2.                                                                                                              |
| `--maxbin_markers`     | `int`     | `107`   | Marker set to choose from for MaxBin., options: 107 or 40. 107 marker genes are present in >95% of bacteria, or 40 marker gene sets that are universal among bacteria and archaea. |
| `--bin_seed`           | `int`     | `1234`  | Set a seed for metaBAT1/2 and CONCOCT.                                                                                                                    |

---

**Logging options**

| Option              | Type      | Default | Description                 |
| ------------------- | --------- | ------- | --------------------------- |
| `--monochrome_logs` | `boolean` | `false` | Output logs in plain ASCII. |

See `mags_maker --help` for the full parameter list including QC, assembly, binning, refinement, and reassembly sub-workflow parameters.

### Advanced usage

#### Determinism

MEGAHIT can run deterministically (`--megahit_deterministic`) however this is not generally recommended as it requires restricting execution to a single CPU (default: 8). This increases MEGAHIT runtime by approximately 7.5×, which can extend the total pipeline runtime depending on the number and size of samples inputted. For example, assembling 20 low-depth metagenomic samples deterministically adds roughly 6 hours to the overall pipeline runtime.

#### Running with only one assembler

By default both metaSPAdes and MEGAHIT assemble the metagenome. To use **only metaSPAdes** turn off MEGAHIT with `--megahit false`. Similarly, to use **only MEGAHIT** turn off metaSPAdes with `--metaspades false`.

### Dependencies

Both BMTagger and taxonomic classification using CheckM2 require databases. Defaults are preconfigured for the Sanger HPC. For external users, please build or download these databases and supply paths to the relevant parameters.

All other dependencies are containerised in publicly available Docker/Singularity images.

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

- **Instability and I/O Errors**: Unpredictble/ transient run errors may occur when running large batches through this pipeline - it is recommended to run in batches of 100 or fewer to avoid this behaviour.
- **BMTagger database not found**: ensure the BMTagger database is available at the configured path. On the Sanger HPC the default path is pre-configured.
- **Assembly fails with insufficient memory**: metaSPAdes is memory-intensive. Adjust the resource labels via a custom config or use only MEGAHIT for low-memory runs.
- **Samples fail assembly**: Check if your input reads lack quality scores (e.g. sra-lite) and if so use `--lock_phred` option.
- **Resuming a failed run**: add `-resume` to your command to restart from cached intermediate results.

For further help, check `.nextflow.log` and the per-process `.command.log` logs in the `work/` directory.

Sanger users may find [this page](https://ssg-confluence.internal.sanger.ac.uk/spaces/PaMI/pages/181078206/General+pipeline+info#Generalpipelineinfo-Troubleshootingafailedpipelinerunandsendingabugreport) useful for troubleshooting Nextflow pipeline runs.

## Issues and Contributions

**GitHub users:** if you find an issue with this pipeline, or would like to suggest an improvement, please log an issue or open a pull request on this repository.

**Sanger users:** if you need internal support, you can raise an issue on the PAM Freshservice portal: https://sanger.freshservice.com/support/catalog/items/426
