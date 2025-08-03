# Metagenomic assembly generation maker Nextflow Pipeline

## Usage

```
Usage:
    nextflow run main.nf

Options:
    --manifest_of_reads / --manifest    Manifest containing paths to fastq files with headers ID,R1,R2. (mandatory)
    --studyid                           Sequencing Study ID. [default: -1] (optional)
    --runid                             Sequencing Run ID. [default: -1] (optional)
    --laneid                            Sequencing Lane ID. [default: -1] (optional)
    --plexid                            Sequencing Plex ID. [default: -1] (optional)
    --target                            Marker of key data product likely to be of interest to customer. [default: 1] (optional)
    --type                              File type. [default: cram] (optional)
    --manifest_of_lanes                 Path to a manifest of iRODS search terms. [default: false] (optional)
    --manifest_ena                      Path to a file of ENA accessions. [default: false] (optional)
    --manifest                          Alias for --manifest_of_reads. (optional)
    --publish_host_data                 Publish the reads determined to originate from the host organism. [default: false] (optional)
    --bmtagger_db                       Path to directory containing BMTagger database. [default: /data/pam/software/bmtagger] (optional)
    --bmtagger_host                     Reference genome version used for host read filtering. [default: T2T-CHM13v2.0] (optional)
    --assembly_stats                    Generate assembly statistics. [default: false] (optional)
    --min_contig                        Minimum threshold for contig size (kb). [default: 1500] (optional)
    --fastspades                        Run SPAdes assembly module only. [default: null] (optional)
    --lock_phred                        Set PHRED quality offset to 33 (SPAdes option). [default: null] (optional)
    --metaspades                        Run metaSPAdes assembly. [default: true] (optional)
    --megahit                           Run MEGAHIT assembly. [default: true] (optional)
    --output_transposed                 Output transposed quast reports. [default: false] (optional)
    --bin_seed                          Set a fixed seed for metaBAT1/2 and CONCOCT. [default: 1234] (optional)
    --maxbin_markers                    Marker set for MaxBin. [default: 140] (optional)
    --metabat1                          Run metaBAT1 binning instead of default metaBAT2. [default: null] (optional)
    --keep_unbinned                     Keep unbinned contigs. [default: false] (optional)
    --checkm1                           Assess quality using the CheckM tool rather than CheckM2. [default: false] (optional)
    --checkm2_db                        Path to directory containing CheckM2 database. [default: /data/pam/software/checkm2_db/uniref100.KO.1.dmnd] (optional)
    --min_completeness                  Minimum completeness threshold. [default: 50] (optional)
    --max_contamination                 Maximum contamination threshold. [default: 5] (optional)
    --remove_ambiguous_contigs          Remove ambiguous contigs instead of default assignment strategy. [default: false] (optional)
    --strict_max                        Strict bin mismatch threshold. [default: 2] (optional)
    --permissive_max                    Permissive bin mismatch threshold. [default: 5] (optional)
    --lock_phred                        Set PHRED quality offset to 33 (SPAdes option). [default: false] (optional)
    --monochrome_logs                   Should logs appear in plain ASCII. [default: false] (optional)

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
