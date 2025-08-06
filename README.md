# mags_maker

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[[_TOC_]]

## Introduction

**mags_maker** is an adaptation of the [generate_mags](https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/team162/generate_mags/-/tree/main) nextflow pipeline that generates MAGs (Metagenome-Assembled Genomes), with additional functionalities summarised below.

## Additional functionality to generate_mags

Assembly Options:

- Assemble metagenomic reads using one of the following options:

  a) Use both metaSPAdes and re-assemble with MEGAHIT (default)
  b) Use only metaSPAdes for assembly (if `--megahit false`)
  c) Use only MEGAHIT for assembly (if `--metaspades false`)

Bin Refinement Options:

- Refine MAG bins using either CheckM2 or CheckM

Reporting:

- A summary report is generated across of the samples at the end of the run

## Pipeline summary

There are 6 stages in this pipeline: QC, assembly, binning, bin refinement, bin reassembly and reporting.

## Getting started

### Running on the farm (Sanger HPC clusters)

1. Load nextflow and singularity modules:

   ```bash
   module load nextflow ISG/singularity
   ```

2. Either:

   - Clone this repository using `git clone --recurse-submodules`  
     OR
   - Use ready-made module: `module load mags_maker`  
     :warning: If using the ready-made module, replace `nextflow run main.nf` with `mags_maker` in all subsequent commands.

3. Start the pipeline  
   For example inputs, please see [Generating a manifest](#generating-a-manifest).

   Example:

   ```bash
   nextflow run main.nf --manifest ./test_data/inputs/test_manifest.csv --outdir my_output
   ```

   It is good practice to submit a dedicated job for the nextflow master process (use the `oversubscribed` queue):

   ```bash
   bsub -o output.o -e error.e -q oversubscribed -R "select[mem>4000] rusage[mem=4000]" -M4000 nextflow run . --manifest ./test_data/inputs/test_manifest.csv --outdir my_output
   ```

   See [usage](#usage) for all available pipeline options.

4. Once your run has finished, check output in the `outdir` and clean up any intermediate files. To do this (assuming no other pipelines are running from the current working directory) run:

   ```bash
   rm -rf work .nextflow*
   ```

> :warning:
> It is strongly recommended that you don't run more than 100 samples at a time through this pipeline to reduce vulnerabilities to transient errors - e.g. LSF and I/O errors.

### Other supported environments

Currently, you can also run this pipeline on a dedicated host machine containing docker (using `-profile docker`) or (`-profile singularity`). No other environments are natively supported at this time.

## Generating a manifest

This pipeline has several input parameters that allow read data to be retrieved locally, from the ENA, and from iRODS. Further detail can be found by using the pipeline `--help` parameter, or [here](./assorted-sub-workflows/README.md).

### Generating a manifest on the farm (Sanger HPC clusters)

It is recommended to use the dedicated the farm module `manifest_generator`:

```
module load manifest_generator
generate_manifest.py -h # for script usage
```

## Usage

```
Sequencing reads input parameters:

There are two ways of providing input reads, which can be combined
      1) through direct input of compressed fastq sequence reads files. This kind of input is passed by specifying the paths to the
      read files via a manifest listing the pair of read files pertaining to a sample, one per row.

      --manifest_of_reads
            default: false
            Manifest containing per-sample paths to .fastq.gz files (optional)

      2) through specification of data to be downloaded from iRODS.
      The selected set of data files is defined by a combination of parameters: studyid, runid, laneid, plexid, target and type (these refer to specifics of the sequencing experiment and data to be retrieved).
      Each parameter restricts the set of data files that match and will be downloaded; when omitted, samples for all possible values of that parameter are retrieved.
      At least one of studyid or runid parameters must be specified. laneid/plexid/target/type are optional parameters that can be provided only in combination with studyid or runid;
      if these are specified without a studyid or runid, the request will be ignored (no iRODS data or metadata download) with a warning
      - this condition aims to avoid indiscriminate download of thousands of files across all possible runs.
      These parameters can be specified through the following command line options: --studyid, --runid, --laneid, --plexid, --target and --type.

      --studyid
            default: -1
            Sequencing Study ID
      --runid
            default: -1
            Sequencing Run ID
      --laneid
            default: -1
            Sequencing Lane ID
      --plexid
            default: -1
            Sequencing Plex ID
      --target
            default: 1
            Marker of key data product likely to be of interest to customer
      --type
            default: cram
            File type

Alternatively, the user can provide a CSV-format manifest listing a batch of such combinations.

      --manifest_of_lanes
            default: false
            Path to a manifest of search terms as specified above.
            At least one of studyid or runid fields, or another field that matches the list of iRODS metadata fields must be specified; other parameters are not mandatory and corresponding
            fields in the CSV manifest file can be left blank. laneid/plexid are only considered when provided alongside a studyid or runid. target/type are only considered in combination with studyid, runid, or other fields.

            Example of manifest 1:
                studyid,runid,laneid,plexid
                ,37822,2,354
                5970,37822,,332
                5970,37822,2,

            Example of manifest 2:
                sample_common_name,type,target
                Romboutsia lituseburensis,cram,1
                Romboutsia lituseburensis,cram,0
      --manifest_ena
            default: false
            Path to a manifest/file of ENA accessions (run, sample or study). Please also set the --accession_type to the appropriate accession type.

-----------------------------------------------------------------

 Aliased options:
      --manifest
            default:
            Alias for --manifest_of_reads (optional)

-----------------------------------------------------------------

 Irods extractor processing options:
      --cleanup_intermediate_files_irods_extractor
            default: false
            delete intermediate CRAM files downloaded from IRODS in work/ folder
      --preexisting_fastq_tag
            default: raw_fastq
            if the expected output fastq files exist in the folder named like this under the result folder for the sample e.g. in results/12345_1#67/raw_fastq/12345_1#67_1.fastq.gz,
            then skip download and any further processing for this sample.
      --split_sep_for_ID_from_fastq
            default: _1.fastq
            separator to recognise sample ID from preexisting file.
      --lane_plex_sep
            default: #
            separator to build sample ID from runid, laneid and plexid. Defaults to '#', which is the iRODS-native syntax.
      --save_method
            default: nested
            save output files in per sample folders (nested) or in one folder (flat)
      --irods_subset_to_skip
            default: phix
            skip data items for which metadata field 'subset' is set to this value
      --combine_same_id_crams
            default: false
            if retrieving read files representing subsets of the same source (files will share the same run, lane and plex IDs), should these files be combined into a 'total' subset i.e. reforming the source read file before subsetting by NPG processing.
      --large_data
            default: false
            If the data is very large instead start from the week queue with more memory (10GB)
      --read_type
            default: Illumina
            Platform the data you wish to receive was sequenced on Illumina|ont

-----------------------------------------------------------------

 General Options:
      --manifest
            default:
            Manifest containing paths to fastq files with headers ID,R1,R2. (mandatory)
      -- qc
            default: metawrap
            Skip metawrap QC step [options: metawrap|skip] (optional)
      --checkm1
            default: false
            Assess quality using the CheckM tool rather than the default - CheckM2 (optional)
      --skip_reassembly
            default: false
            Skip the reassembly process (optional)
      --outdir
            default: ./results
            Directory to store pipeline output (optional)


-----------------------------------------------------------------

 Quality Control Options:
      -- publish_host_data
            default: false
            Publish the reads determined to originate from the host organism (optional)
      -- bmtagger_db
            default: /data/pam/software/bmtagger
            Path to directory containing BMTagger database (optional)
      -- bmtagger_host
            default: T2T-CHM13v2.0
            Reference genome version used for host read filtering (optional)

-----------------------------------------------------------------

Assembly Subworkflow Options:
    --assembly_stats
            default: false
            Generate assembly statistics (optional)
    --min_contig
            default: 1500
            Minimum threshold for contig size (kb) (optional)
    --fastspades
            default: null
            Run SPAdes assembly module only (optional)
    --lock_phred
            default: null
            Set PHRED quality offset to 33 (SPAdes option) (optional)
    --metaspades
            default: true
            Run metaSPAdes assembly (optional)
    --megahit
            default: true
            Run MEGAHIT assembly (optional)
    --output_transposed
            default: false
            Output transposed quast reports (optional)

-----------------------------------------------------------------

Binning Subworkflow Options:
    --bin_seed
            default: 1234
            Set a fixed seed for metaBAT1/2 and CONCOCT (optional)
    --maxbin_markers
            default: 140
            Marker set to choose from for MaxBin. 107 marker genes present in >95% of bacteria, or 40 marker gene sets that are universal among bacteria and archaea (optional)
    --metabat1
            default: null
            Run metaBAT1 binning instead of default metaBAT2 (optional)
    --keep_unbinned
            default: false
            Keep unbinned contigs (optional)

-----------------------------------------------------------------

Binning Refinement Subworkflow Options:
    --checkm2_db
            default: /data/pam/software/checkm2_db/uniref100.KO.1.dmnd
            Path to directory containing CheckM2 database (optional)
    --min_completeness:
            default: 50
            Minimum completeness threshold (%) (optional)
    --max_contamination:
            default: 5
            Maximum contamination threshold (%) (optional)
    --remove_ambiguous_contigs
            default: false
            Dereplicate by removing ambiguous contigs rather than the default strategy of assigning them to the highest quality potential bin (optional)

-----------------------------------------------------------------

Reassemble Subworkflow Options:
    --strict_max
            default: 2
            Strict bin mismatch threshold (optional)
    --permissive_max
            default: 5
            Permissive bin mismatch threshold (optional)
    --min_contig
            default: 1500
            help_text: Minimum threshold for contig size (kb) (optional)
    --min_completeness:
            default: 50
            Minimum completeness threshold (%) (optional)
    --max_contamination:
            default: 5
            Maximum contamination threshold (%) (optional)
    --checkm2_db
            default: /data/pam/software/checkm2_db/uniref100.KO.1.dmnd
            Path to directory containing CheckM2 database (optional)
    --lock_phred
            default: false
            Set PHRED quality offset to 33 (SPAdes option) (optional)

-----------------------------------------------------------------
```

## Output and intermediate file cleanup

By default, this pipeline will publish the results to a `results` folder, this can be changed using the `--outdir` argument.

For instance, the output directory could look like:

```

example_output
├── bin_merging
│    ├── <sample_id>_merge.log
├── metawrap_qc
│   ├── cleaned_reads
│   │   ├── <sample_id>_clean_1.fastq.gz
│   │   ├── <sample_id>_clean_2.fastq.gz
│   │   ├── ...
│   ├── host_reads
│   │   ├── <sample_id>_host_1.fastq.gz
│   │   ├── <sample_id>_host_1.fastq.gz
│   │   ├── ...
│   ├── read_removal_statistics.csv
├── <sample_id>
│   ├── checkm1
│   │   ├── <bin_tool>_summary.tsv
│   │   ├── ...
│   ├── checkm2
│   │   ├── <bin_tool>_summary.tsv
│   │   ├── ...
│   ├── <sample_id>_best_bins
│   │   ├── <length>_<sample_id>_bin_1_<strict/permissive/origin>.fasta
│   │   ├── ...
│   ├── <sample_id>_best_bins_summary.tsv
│   ├── quast
│   │   ├── transposed_report.tsv
└── final_summary.tsv

```

Output folders are described in the following table:
| folder | description |
| --------- | --------------------------------------------------------- |
| bin_merging | Contains a log per sample stating parameters used and number of bins kept/discarded from each tool output when merging bins together |
| metawrap_qc | Contains host reads (fastq.gz) (if `--publish_host_data` option is used), cleaned/host-removed sample reads (fastq.gz), as well as read_removal_statistics.csv generated during the metawrap qc step (if `--qc` option is used) |
| <sample_id> | Contains the checkm1/checkm2 summary stats for each binning tool from bin refinement, the best bin assemblies after reassembly and the checkm1/checkm2 summary stats for the best bins chosen |
| final_summary.tsv | Contains all samples checkm1/checkm2 summary stats for the best bins chosen |

## Credits

This pipeline was originally designed as a reimplementation of metaWRAP (based on version 1.3.2; https://github.com/bxlab/metaWRAP). For further information please refer to the MetaWRAP paper: [MetaWRAP - a flexible pipeline for genome-resolved metagenomic data analysis](https://microbiomejournal.biomedcentral.com/articles/10.1186/s40168-018-0541-1)

## Support

For further information or help, don't hesitate to get in touch via [pam-informatics@sanger.ac.uk](mailto:pam-informatics@sanger.ac.uk).
