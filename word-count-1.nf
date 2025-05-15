#!/usr/bin/env nextflow

// Define input directory or file(s), default to 'data/*.txt'
params.input = 'data/pg84.txt'

// Process to count words in a text file
process countWords {
    publishDir 'output', mode: 'copy'

    input:
        path file

    output:
        path "${file.simpleName}_wordcount.txt"

    script:
    """
    wc -w ${file} > ${file.simpleName}_wordcount.txt
    """
}

// Main workflow
workflow {
    // Create a file channel from the input pattern
    input_files = Channel.fromPath(params.input)

    // Count words in each file
    countWords(input_files)
}