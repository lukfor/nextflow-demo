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
        // Declare that this process will produce a file called 'output.txt'
        path "output.txt"

    script:
    """
    # The shell script to run for this process
    echo 'Hello ${name}!' > output.txt
    """
}

// Define the main workflow block
workflow {
    // Read name from command-line parameter and pass to process
    sayHello(params.name)
}