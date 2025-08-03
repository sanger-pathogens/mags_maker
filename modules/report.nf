process PUBLISH_RESULTS {
    label "cpu_1"
    label "mem_100M"
    label "time_1"

    container 'quay.io/sangerpathogens/python-curl:3.11'

    publishDir mode: 'copy', path: "${params.outdir}/${meta.ID}"

    input:
    tuple val(meta), path(fastas), path(report_txt)

    output:
    tuple val(meta), path(fastas), path(report_txt), emit: report_and_bins

    script:
    """
    touch publish_bin.txt
    """
}

process SUMMARY {
    label "cpu_1"
    label "mem_100M"
    label "time_1"

    container 'quay.io/sangerpathogens/python-curl:3.11'

    publishDir mode: 'copy', path: "${params.outdir}"

    input:
    path('???.tsv')

    output:
    path(summary), emit: summary_out

    script:
    summary = "final_summary.tsv"
    """
    head -n 1 001.tsv > ${summary} && tail -n +2 -q *.tsv >> ${summary}
    """
}
