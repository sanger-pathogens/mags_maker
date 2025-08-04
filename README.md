# mags_maker

## Introduction

**mags_maker** is an adaption of the [generate_mags](https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/team162/generate_mags/-/tree/main) nextflow pipeline that generates MAGs (Metagenome-Assembled Genomes). 

## Pipeline summary

There are 5 stages in this pipeline: QC, assembly, binning, bin refinement, bin reassembly and reporting.

## Getting started

### Running on the farm (Sanger HPC clusters)

1. Load nextflow and singularity modules:

   ```bash
   module load nextflow ISG/singularity
   ```

2. Either:

   - Clone this repository using `git clone --recurse-submodules`  
     OR
   - Use ready-made module: `module load generate_mags`  
     :warning: If using the read-made module, replace `nextflow run main.nf` with `generate_mags` in all subsequent commands.

3. Start the pipeline  
   For example input, please see [Generating a manifest](#generating-a-manifest).

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

```
Sequencing reads input parameters

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
 Aliased options
      --manifest
            default:
            Alias for --manifest_of_reads (optional)
-----------------------------------------------------------------
 Quality Control Options
      -- publish_host_data
            default: false
            Publish the reads determined to originate from the host organism
      -- bmtagger_db
            default: /data/pam/software/bmtagger
            Path to directory containing BMTagger database
      -- bmtagger_host
            default: T2T-CHM13v2.0
            Reference genome version used for host read filtering

-----------------------------------------------------------------

Assembly Subworkflow Options
    --assembly_stats            
            default: false        
            Generate assembly statistics. [default: false] (optional)
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
            Marker set to choose from for MaxBin. 107 marker genes present in >95% of bacteria, or 40 marker gene sets that are universal among bacteria and archaea. (optional)
    --metabat1
            default: null                           
            Run metaBAT1 binning instead of default metaBAT2 (optional)
    --keep_unbinned       
            default: false              
            Keep unbinned contigs. [default: false] (optional)
-----------------------------------------------------------------
Binning Refinement Subworkflow Options:
    --checkm1
            default: false 
            Assess quality using the CheckM tool rather than the default - CheckM2 (optional)
    --checkm2_db
            default: /data/pam/software/checkm2_db/uniref100.KO.1.dmnd
            Path to directory containing CheckM2 database (optional)
    --min_completeness:
            default: 50 
            Minimum completeness threshold (%) 
    --max_contamination:
            default: 5
            Maximum contamination threshold (%)
    -- remove_ambiguous_contigs  
            default: false
            Dereplicate by removing ambiguous contigs rather than the default strategy of assigning them to the highest quality potential bin

Reassemble Subworkflow Options:

    --strict_max 
            default: 2
            Strict bin mismatch threshold (optional)
    --permissive_max
            default: 5 
            Permissive bin mismatch threshold (optional)
    --min_contig
            default: 1500
            help_text: Minimum threshold for contig size (kb).
    --min_completeness:
            default: 50 
            Minimum completeness threshold (%) 
    --max_contamination:
            default: 5
            Maximum contamination threshold (%)
    --checkm2_db
            default: /data/pam/software/checkm2_db/uniref100.KO.1.dmnd
            Path to directory containing CheckM2 database (optional)
    --checkm1
            default: false 
            Assess quality using the CheckM tool rather than the default - CheckM2 (optional)
   --lock_phred
            default: false
            Set PHRED quality offset to 33 (SPAdes option) (optional)

## Generating manifests

### On Wellcome Sanger Institute "farm" HPC

It is recommended to use the dedicated the farm module `manifest_generator`:

```

module load manifest_generator
generate_manifest.py -h # for script usage

```

Alternatively, you can use the scripts bundled with this repository (deprecated).

If your data is stored in the PaM informatics pipeline system, you can use the following method:

```

./generate_manifest_from_lanes.sh -l <lanes_file>

```

For more information, run:

```

./generate_manifest_from_lanes.sh -h

```

If your data is not stored in the PaM informatics pipeline system, use the following method:

### Step 1:

Obtain fastq paths:
`ls -d -1 <path>/*.fastq.gz > fastq_paths.txt`

### Step 2:

Generate manifest:

```

./generate_manifest.sh fastq_paths.txt

```

This will output the manifest to `manifest.csv` which can be fed into the nextflow pipeline

## Dependencies

This pipeline relies on the following modules:

```

ISG/singularity/3.6.4
nextflow/22.10.6-5843

```

```
