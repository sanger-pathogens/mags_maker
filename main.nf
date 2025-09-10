#!/usr/bin/env nextflow
// Copyright (C) 2024 Genome Research Ltd.

/*
========================================================================================
    HELP
========================================================================================
*/

def logo = NextflowTool.logo(workflow, params.monochrome_logs)

log.info logo

NextflowTool.commandLineParams(workflow.commandLine, log, params.monochrome_logs)


def printHelp() {
    NextflowTool.help_message("${workflow.ProjectDir}/schema.json", 
                              ["${workflow.ProjectDir}/assorted-sub-workflows/mixed_input/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/mags_maker/metawrap_qc/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/mags_maker/assemble/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/mags_maker/binning/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/mags_maker/bin_refinement/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/mags_maker/reassemble/schema.json"
                              ],
    params.monochrome_logs, log)
}

/*
========================================================================================
    IMPORT MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// SUBWORKFLOWS
//

include { MIXED_INPUT } from './assorted-sub-workflows/mixed_input/mixed_input.nf'
include { MAGS_MAKER  } from './subworkflows/mags_maker.nf'

/*
Helper Scripts
*/

include { validate_parameters } from './modules/validate.nf'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow {
    if (params.help) {
        printHelp()
        exit 0
    }

    validate_parameters()


    MIXED_INPUT
    | MAGS_MAKER
    
}