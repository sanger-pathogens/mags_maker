include { METAWRAP_QC                    } from '../assorted-sub-workflows/mags_maker/metawrap_qc/metawrap_qc.nf'
include { METAWRAP_ASSEMBLE              } from '../assorted-sub-workflows/mags_maker/assemble/assembly.nf'
include { METAWRAP_BINNING               } from '../assorted-sub-workflows/mags_maker/binning/binning.nf'
include { METAWRAP_BIN_REFINEMENT        } from '../assorted-sub-workflows/mags_maker/bin_refinement/bin_refinement.nf'
include { METAWRAP_REASSEMBLY            } from '../assorted-sub-workflows/mags_maker/reassemble/reassembly.nf'
include { PUBLISH_RESULTS; 
          SUMMARY                        } from '../modules/report.nf'

/*
Main workflow
*/

workflow MAGS_MAKER {
    take:
    reads_ch

    main:
    switch (params.qc) {
        case "metawrap":
            METAWRAP_QC(reads_ch)
            | set { ready_reads }

            break

        case "skip":
            reads_ch
            | set { ready_reads }

            break
        
        default:
            log.error("input --qc: ${params.qc} was not one of metawrap|skip")

    }

    switch (params.pipeline_termination) {
        case [null, "null"]:
            METAWRAP_ASSEMBLE(ready_reads)
            | set { contigs }

            METAWRAP_BINNING(contigs, ready_reads)
            | set { bins }

            METAWRAP_BIN_REFINEMENT(bins, ready_reads)
            | set { refined_bins }
            
            if (!params.skip_reassembly) {
                METAWRAP_REASSEMBLY(refined_bins, ready_reads)
                | set { final_bins }
            } else {
                refined_bins
                | set { final_bins }
            }

            PUBLISH_RESULTS(final_bins)

            final_bins
            | map { meta, fastas, checkmReport -> [checkmReport]}
            | collect
            | SUMMARY



            METAWRAP_QC(reads_ch)
            | set { ready_reads }

            break

        case "assembly":

            if (!params.publish_unbinned_contigs) { 
                error "When --pipeline_termination: ${params.pipeline_termination} --publish_unbinned_contigs must be true"
                System.exit(1)
            }

            METAWRAP_ASSEMBLE(ready_reads)
            | set { contigs }

            break
        
        default:
            log.error("input --pipeline_termination: ${params.pipeline_termination} was not one of null|assembly")

    }



}