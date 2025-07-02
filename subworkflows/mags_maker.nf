include { METAWRAP_QC                    } from '../assorted-sub-workflows/generate_mags/metawrap_qc/metawrap_qc.nf'
include { METAWRAP_ASSEMBLE              } from '../assorted-sub-workflows/generate_mags/assemble/assembly.nf'
include { METAWRAP_BINNING               } from '../assorted-sub-workflows/generate_mags/binning/binning.nf'
include { METAWRAP_BIN_REFINEMENT        } from '../assorted-sub-workflows/generate_mags/bin_refinement/bin_refinement.nf'
include { METAWRAP_REASSEMBLY            } from '../assorted-sub-workflows/generate_mags/reassemble/reassembly.nf'
include { REPORT_BINS                    } from '../assorted-sub-workflows/generate_mags/reporting/reporting.nf'

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

    REPORT_BINS(final_bins)
}