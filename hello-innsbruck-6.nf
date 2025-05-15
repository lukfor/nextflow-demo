#!/usr/bin/env nextflow

// Set a default value for the 'name' parameter
params.name = 'Innsbruck'

// Define a process called 'sayHello'
process sayHello {
    // Specify the directory where output files will be saved
    // 'copy' mode means the file is copied to the directory (original remains in working directory)
    publishDir 'output', mode: 'copy'

    input:
        // Take a string value as input
        val name

    output:
        // We need to update hte name of the output
        path "output_${name}.txt"

    script:
    """
    # The shell script to run for this process
    echo 'Hello ${name}!' > output_${name}.txt
    """
}

// Define a process to collect all greeting files and merge them into a single output
process collectGreetings {
    // Save the combined output file in the results folder
    publishDir 'output', mode: 'copy'

    input:
        // Accept a list of paths (all output files from sayHello)
        path input_files

    output:
        // Define the single merged output file
        path "output.txt"

    script:
    """
    # Concatenate all input greeting files into one
    cat ${input_files} > 'output.txt'
    """
}

// Define the main workflow block
workflow {
    // create a channel for inputs
    name_ch = Channel.of('World', 'Lukas', 'Innsbruck')

    // Call the sayHello process for each name in the channel
    // It will generate one greeting file per name
    hello_ch = sayHello(name_ch)

    // collect all the greetings into one file
    // we need to call collect to run the process only once with all items.
    // otherwise we would start it for each item and no merging is performed
    collectGreetings(hello_ch.collect())
}