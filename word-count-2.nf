#!/usr/bin/env nextflow

// Define input directory or file(s), default to 'data/*.txt'
params.input = 'data/pg84.txt'
params.output = "output"

// Process to count words in a text file
process countWords {
    publishDir params.output, mode: 'copy'

    input:
        path file

    output:
        path "${file.simpleName}_wordcount.txt"

    script:
    """
    wc -w ${file} > ${file.simpleName}_wordcount.txt
    """
}

// Define a process to collect all counts and merge them into a single output
process collectCountings {
    // Save the combined output file in the results folder
    publishDir params.output, mode: 'copy'

    input:
        // Accept a list of paths (all output files from countWords)
        path input_files

    output:
        // Define the single merged output file
        path "counts.txt"

    script:
    """
    # Concatenate all input greeting files into one
    cat ${input_files} > 'counts.txt'
    """
}

// Main workflow
workflow {
    // Create a file channel from the input pattern
    input_files = Channel.fromPath(params.input)

    // Count words in each file
    wordcounts = countWords(input_files)

    merged = collectCountings(wordcounts.collect())
}