#!/usr/bin/env nextflow

// Define input directory or file(s), default to 'data/*.txt'
params.input = 'data/pg84.txt'
params.output = "output"

// Process to count words in a text file
process countWords {

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

// Process to plot histogram using R and ggplot2
process plotResults {
    publishDir params.output, mode: 'copy'

    input:
        path merged_counts

    output:
        path 'wordcount_barplot.png'

    script:
    """
    #!RScript
    library(ggplot2);
    data <- read.table('${merged_counts}', col.names=c('count', 'file'));
    data\$file <- factor(data\$file, levels = data\$file);
    # Create bar plot with file names on x-axis and word count on y-axis
    png('wordcount_barplot.png', width=1024, height=768);
    ggplot(data, aes(x = file, y = count)) +
        geom_bar(stat = 'identity', fill = 'steelblue') +
        labs(title = 'Word Count per File', x = 'File', y = 'Word Count') +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1));
    dev.off();
    """
}

// Main workflow
workflow {
    // Create a file channel from the input pattern
    input_files = Channel.fromPath(params.input)

    // Count words in each file
    wordcounts = countWords(input_files)

    merged = collectCountings(wordcounts.collect())

    plotResults(merged)

}