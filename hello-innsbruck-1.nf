#!/usr/bin/env nextflow

// Define a process called 'sayHello'
process sayHello {
    // Specify the directory where output files will be saved
    // 'copy' mode means the file is copied to the directory (original remains in working directory)
    publishDir 'output', mode: 'copy'

    output:
        // Declare that this process will produce a file called 'output.txt'
        path "output.txt"

    script:
    """
    # The shell script to run for this process
    echo 'Hello Innsbruck!' > output.txt
    """
}

// Define the main workflow block
workflow {
    // Call the 'sayHello' process
    sayHello()
}