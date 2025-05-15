
## Anatomy of a Nextflow Pipeline

`hello-innsbruck-1.nf`:

\small
```groovy
process sayHello {
    publishDir 'output', mode: 'copy'
    output:
        path 'output.txt'
    script:
    """
    echo 'Hello Innsbruck!' > output.txt
    """
}

workflow {
    sayHello()
}
```



## The `process` definition

Define a process called 'sayHello':

\small
```groovy
process sayHello {
    // Specify the directory where output files will be saved
    publishDir 'output', mode: 'copy'

    // Declare that this process will produce a file called 'output.txt'
    output:
        path "output.txt"

    script:
    // The shell script to run for this process
    """
    echo 'Hello Innsbruck!' > output.txt
    """
}
```



## The `workflow` definition

Defines the main workflow block and call the sayHello process:

\small
```groovy
workflow {
    sayHello()
}
```
\normalsize
The workflow block is where we connect different processes together.



## Running the Workflow

### Running Nextflow with the `run` Subcommand

```bash
nextflow run hello-innsbruck-1.nf
```

This command creates a file at `output/output.txt` containing the text `Hello Innsbruck`.

### Re-launching with `-resume`

Using the `-resume` option reruns the pipeline, but only executes processes whose inputs have changed:

```bash
nextflow run hello-innsbruck-1.nf -resume
```



## Process Inputs (1/2)

Inputs can be used in the `script` block with `${input_name}`:

\small
```groovy
process sayHello {
    publishDir 'output', mode: 'copy'
    
    input:
        val name
    output: 
        path "output.txt"

    script:
    """
    echo 'Hello ${name}' > output.txt
    """
}
```




## Process Inputs (2/2)

### Workflow Block

In the `workflow` block, inputs can be passed to processes like function arguments:

\small
```groovy
workflow {
    sayHello("Innsbruck")
}
```

### Rerun the pipeline

```bash
nextflow run hello-innsbruck-2.nf
```



## Parameters

### Define parameters with default values at the beginning of your script
```groovy
params.name = 'Innsbruck'
```
- If you do not specify `--name`, it defaults to `'Innsbruck'`.
- If you run with `--name 'Lukas'`, it overrides the default.

### Use the parameter in the workflow or processes

```groovy
workflow {
    sayHello(params.name)
}
```

### Run the workflow with a custom parameter

```bash
nextflow run hello-innsbruck-3.nf --name 'Lukas'
```



## Channels (1/3)

![](images/part-03/channel-process.png)



## Channels (1/3)

This enable parallelization:

![](images/part-03/serial_vs_parallel.png)



## Channels (2/3)

### Instead of a single value, we can use a channel:

```groovy
workflow {

    // create a channel for inputs
    name_ch = Channel.of('World', 'Lukas', 'Innsbruck')

    // call process for each item in the channel
    sayHello(name_ch)
}
```

### Execute the pipeline using the defined channel

```bash
nextflow run hello-innsbruck-4.nf
```



## Channels (3/3)

- **Problem:** Each execution of the process writes to the same output file, overwriting previous results.
- **Solution:** Use unique filenames by including input values in the filename.

\small
```groovy
process sayHello {
    publishDir 'results', mode: 'copy'
    input:
        val name
    output:
        path "output_${name}.txt" // We need to update the name of the output
    script:
    """
    # The shell script to run for this process
    echo 'Hello ${name}!' > output_${name}.txt
    """
}
```

```bash
nextflow run hello-innsbruck-5.nf
```



## Channels: `collect` Operator

- The `collect` operator gathers all emitted values into a single list.
- This is useful when you want to pass all items at once to a single process.

![](images/part-03/serial_vs_parallel.png)



## Merging Output Files (1/2)

### Define a process to collect all greeting files and merge them into a single output

\small
```groovy
process collectGreetings {
    publishDir 'output', mode: 'copy'
    input:
        // Accept a list of paths (all output files from sayHello)
        path input_files
    output:
        path "output.txt"
    script:
    """
    # Concatenate all input greeting files into one
    cat ${input_files} > 'output.txt'
    """
}
```

## Merging Output Files (2/2)

### Using the `collect` Operator

- The output channel from `sayHello` contains one item per output file.
- To merge these files, we need to use `collect` so the next process runs **once** with all items.
- Without `collect`, the downstream process would run **once per item**.
  \small
  ```groovy
  workflow {
      name_ch = Channel.of('World', 'Lukas', 'Innsbruck')
      hello_ch = sayHello(name_ch)
      collectGreetings(hello_ch.collect())
  }
  ```

\normalsize
### Run workflow

\small
```bash
nextflow run hello-innsbruck-6.nf
```



## Recap

**Processes** define tasks and use `input`, `output`, and `script` blocks.

**Workflows** connect processes and pass data between them.

**Parameters** allow customization using `params.<name>` and `--<name>` on the command line.

**Channels** handle data flow:

- `Channel.of(...)` creates a channel with static values.
- Channels trigger processes for each item.
- Use `.collect()` to group multiple values into one input.

**Output merging**: Use `collect` when you want a process to handle all outputs at once (e.g., merging files).

# Working with Files



## Channels from Files (1/2)

### File and Paths (`path`)

- Instead of a `val` input, we define a `path` input (used for file paths).
- Paths are automatically staged by Nextflow
- if the process runs on a different machine, Nextflow ensures the file is available there.
  \small
  ```groovy
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
  ```

## Channels from Files (1/2)

### `Channel.fromPath()`
- Channel.fromPath() creates a channel from one or more file paths.
- Supports wildcards (e.g. "data/*.txt") for batch processing.
- Ensures each matching file is passed individually to the process.
  ```groovy
  params.input = 'data/pg84.txt'

  workflow {
      // Create a file channel from the input pattern
      input_files = Channel.fromPath(params.input)
      countWords(input_files)
  }
  ```

## Run Workflow

### Run with 1 File

```bash
nextflow run word-count-1.nf --input data/pg84.txt
```
### Run with Multiple Files

```bash
nextflow run word-count-1.nf --input "data/*.txt"  
```

**Important:** Use quotes (`" "`) around the pattern to prevent the shell from expanding the wildcard (*). This ensures Nextflow receives the pattern.



## Merge results from multiple files (1/2)

We can add the same merge logic from the `hello-innsbruck` example:

\small
```groovy
process collectCountings {
    publishDir 'output', mode: 'copy'

    input:
        path input_files

    output:
        path "counts.txt"

    script:
    """
    # Concatenate all input greeting files into one
    cat ${input_files} > 'counts.txt'
    """
}
```



## Merge results from multiple files (2/2)

```groovy
workflow {
    input_files = Channel.fromPath(params.input)
    wordcounts = countWords(input_files)
    merged = collectCountings(wordcounts.collect())
}
```

```bash
nextflow run word-count-2.nf --input "data/*.txt"  
```



## Configurations

### Parameters
- Parameters can be set via the command line
- Or defined in a separate config file
- Config files are useful for managing different experiments or setups

### `gutenberg.config`:
```groovy
params {
    imput = "data/*.txt"
    output = "output/gutenberg"
}
```

### Run with Configuration File
```bash
nextflow run word-count-2.nf -c gutenberg.config
```

<!->

# Dependencies and Containers



## Plot Results with R (1/2)

Use a simple r script to create a barplot of the merged file

\small
```groovy
process plotResults {
    publishDir 'output', mode: 'copy'
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
    png('wordcount_barplot.png', width=1024, height=768);
    ggplot(data, aes(x = file, y = count)) +
        geom_bar(stat = 'identity', fill = 'steelblue') +
        labs(title = 'Word Count per File', x = 'File', y = 'Word Count')
    dev.off();
    """
}
```



## Plot Results with R (2/2)

```groovy
workflow {
    input_files = Channel.fromPath(params.input)
    wordcounts = countWords(input_files)
    merged = collectCountings(wordcounts.collect())
}
```

### Run Pipeline

```bash
nextflow run word-count-3.nf --input "data/*.txt"  
```



## Containers (1/3)

### How can we use environments?

**Option A: Use a Conda environment**

* Activate a Conda environment before running the workflow.
* Works well when executing the workflow on a **single machine**.
* Not ideal for distributed or cluster environments.

**Option B: Use one environment or one container per process**  *Recommended*

* Assign a specific container or environment to each process in the workflow.
* Ensures reproducibility and isolation.
* Works well across multiple machines or in HPC/cluster settings.
* Supports technologies like **Docker**, **Singularity**, or **Conda** (with Nextflow integration).



## Containers (2/3)

### Configuration
- Add a profile to `nextflow.config`.
- `nextflow.config` uses the same syntax as process-specific configuration files.
- It is loaded automatically and used to set global options.
- A user-provided config (via `-c`) can override the default `nextflow.config`.

### Singularity

\small
```groovy
profiles {
    singularity {
        singularity.enabled = true
        singularity.autoMounts = true
        process.container = '/mnt/genepi-lehre/teaching/scicomp/singularity/gwas-example.sif'
    }
}
```

## Containers (3/3)

### Run with profile

```bash
nextflow run word-count-3.nf -profile singularity --input "data/*.txt"
```





## Example

A a real example with our GWAS pipeline

[https://github.com/lukfor/gwas-example](https://github.com/lukfor/gwas-example)


### Running from GitHub

```bash
nextflow run lukfor/gwas-example -profile singularity
```

