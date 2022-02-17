# scRNA-seq Snakemake Pipeline at Luolab (Smartseq2/STRTseq hybrid protocol)
Snakemake pipeline for Upstream processing of scRNA-seq libraries generated by a customized Smartseq2/STRTseq hybrid protocol - **from fastq to count table**.

## Prerequisites

### Build Required Tools

This pipeline is based on [`Snakemake`](https://snakemake.github.io/), which is a python-based [workflow management system](https://en.wikipedia.org/wiki/Workflow_management_system) focusing on pipelining bioinformatics analysis. To install snakemake, follow the [tutorial](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) from the official documentation of snakemake.

We highly recommend using [`conda`](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)/[`mamba`](https://github.com/mamba-org/mamba) for installation of snakemake and for package management. 

After installing `snakemake`, you may decide whether you'd like to use the [`Integrated Package Management`](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html) feature of Snakemake.  
If your decision is yes (recommended for beginners), you can skip the rest of this section. All you have to do is activate the `--use-conda` flag everytime you invoke the `snakemake` command for pipeline run. `Snakemake` will automatically build a new environment as described in the `workflow/envs/master.yaml` to setup the required packages for you.

For advanced users, if you decide to build everything yourself, please install the following additional packages:

```
umi_tools (>=1.1.2)
STAR (>=2.5.4)
subread (>=1.6.3)
sambamba (>=0.8.0)
seaborn (=0.11.2)
```

### Clone the Repository

To use the pipeline, install `git` and clone the repo to your local computer.

```
git clone https://github.com/RuiyuRayWang/ScRNAseq_smkpipe_at_Luolab.git
```

## Usage

### Example Run

We recommend that the first-time users always perform an example run before proceeding to subsequent steps. The example run serves as a check to the installation of the pipline. If the example runs smoothly, you know this pipeline is set up properly.

For the Example run, refer to the [Example run markdown](https://github.com/RuiyuRayWang/ScRNAseq_smkpipe_at_Luolab/blob/main/workflow/data/WangRuiyu/Example/README.md).

### Preparations

Once everything is setup, prepare your own real data that will be analyzed. 

In the `config/` directory, edit sample metadata by filling in `sample_table.csv` and `config.yaml` files. These will be used by the pipeline to locate your data and setup the file structure. Make sure to specify in `config.yaml` the correct **genome index**, **barcode-ground-truth list** and **gtf annotations**. You can use the `config/sample_table_example.csv` and `config/config_example.yaml` as a templates to guide your through this step.

We highly recommend the users take a close look at the file structure generated from the example run (sub-folders in `workflow/data`).

For each library, we use a dedicated folder to hold the `R1` and `R2` fastq read pairs.

For better file structure management, we recommend to put raw fastq files (`fastqs/`), intermediate files (`alignments/`), logs (`logs/`), and aggregated final results (`outs/`) in dedicated locations in your harddisk, and construct symbolic links between your `data/` directory and these inputs and outputs (see repo structure below).

Depending on your system specifications, you may also need to manually edit some parameters in the pipeline to make it work (i.e. `pipeline.smk`). ## TODO: Update details, integrate into config.yaml

### Run

Once you're finished with the preparations above, you should be ready to run the pipeline on real data. Activate a shell prompt, change to main directory (i.e. `ScRNAseq_smkpipe_at_Luolab/`) and execute the following command to start a dry run:

```
snakemake -n
```

It is highly recommended that you perform a dry run everytime before you make an actual run of the pipeline, because it can tell you if there's a bug/error/mistake in your preparation steps.

If the dry run is successful, execute the following command to make an actual run:

```
snakemake --cores 16 --use-conda
```

Replace the `16` with the number of CPU cores you wish to be used. 

Note that the command above uses the [`Integrated Package Management`](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html) feature of Snakemake, thus on the first run, it will take some time for Snakemake to setup a new environment.

If you prefer to use an environment built by yourself, just drop the `--use-conda` flag: 

```
snakemake --cores 16
```

### Generate snakemake report for jobs

In order to generate `report` for your job, you have to switch the pipeline to another `git` branch called `report`.

Under the main directory of the pipeline, activate a shell prompt and fetch the branch from remote: 

```
git branch report
git branch --set-upstream-to=origin/report report
git checkout report
git pull
```

Invoke `snakemake` with `--report` tag to generate the report. For demonstration purposes, we generate a report for the [Example run](#example-run) dataset.

```
snakemake --report report.html --configfile config/config_example.yaml
```

You should see a `report.html` output in your current working directory.

## Notes

* 2022/2/17:  
Updates: incorporated snakemake `report` feature to generate runtime summaries and quality controls (QCs) of jobs.  
Due to a wired conflict between snakemake internal mechanism and the way we handle STAR Shared memory feature, the report mechanism can be only instantiated in a separate branch apart from the `main` branch. See [report section](#generate-snakemake-report-for-jobs) in this doc.

* 2022/2/1:  
To avoid misunderstanding from the users, a clarification should be made: the scRNA-seq protocol used in Luolab, for which this repo is design for, is NOT entirely the same as the standard Smartseq2 protocol described in [Picelli et al. (2013)](https://www.nature.com/articles/nmeth.2639). 

The protocol was modified in a way that resembles **a hybrid of Smartseq2 and STRTseq** ([Islam et al., 2011](https://genome.cshlp.org/content/21/7/1160)). A major distinction between the Smartseq2 and our method is that in the standard Smartseq2, one library stands for one cell; whereas in our method, 48 cells are multiplex in a single library, and later demultiplexed by cell barcodes. One advantage of this strategy is that it can alleviate the high manual labors involved in the standard Smartseq2 protocol.

We have modified the nomenclature used in this repo to avoid misconceptions (i.e. direct reference to Smartseq2 changed to Smartseq2/STRTseq hybrid).

* When executing the pipeline, depending on the system's hardware, one may receive the following error:  
> exiting because of OUTPUT FILE error: could not create output file SampleName-STARtmp//BAMsort/... SOLUTION: check that the path exists and you have write permission for this file. Also check ulimit -n and increase it to allow more open files.

This is because STAR creates lots of temporary files during its the run and has reached the file creation limit set by the system. A simple workaround is to set the `threads:` in `pipeline.smk` `rule STAR: (# Step 4-1: Map reads)` to lower values, i.e. 32->16.

* Within a particular project, we recommended that the user keep the STAR version unchanged and use it throughout the whole course of the project as new data comes in. This is because genomes generated by different versions of STARs are incompatible with each other. For example, an alignment job run by STAR v2.7.9 will not accept a genome index generated by STAR v2.6.1.

## Structure of the Repository

The structure of this repository is largely inspired by the template defined in [snakmake docs](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html).

```
├── .gitignore
├── README.md
├── LICENSE
├── workflow
|   ├── data
|   |   ├── User1
|   │   │   ├── Project1
|   │   │   │   ├── fastqs
|   │   │   │   ├── alignments
|   │   │   │   ├── outs
|   │   │   │   ├── miscs
|   │   │   │   └── logs
|   │   │   └── Project2
|   |   └── User2
│   ├── rules
|   │   ├── common.smk
|   │   └── pipeline.smk
│   ├── envs
|   │   ├── tool1.yaml
|   │   └── tool2.yaml
│   ├── scripts
|   │   ├── wash_whitelist.py
|   │   └── script2.R
│   ├── notebooks
|   │   ├── notebook1.py.ipynb
|   │   └── notebook2.r.ipynb
│   ├── report
|   │   ├── plot1.rst
|   │   └── plot2.rst
|   └── Snakefile
└── config
    ├── config.yaml
    └── sample_table.tsv
```

## Pipeline Details

We adopt a comprehensive pipeline described in the [umi_tools documentation](https://umi-tools.readthedocs.io/en/latest/Single_cell_tutorial.html). Some custom modification were made to the original pipeline (i.e. multi-threading, parallel processing, STAR "shared memory" modules) for speed boost. Several other minor modification were made in order to accomodate for the modified chemistry and to improve the performance of the pipeline (i.e. better alignment quality).

```
# Step 1: Identify correct cell barcodes (umi_tools whitelist)
umi_tools whitelist --bc-pattern=CCCCCCCCNNNNNNNN \
		          --log=LIBRARY_whitelist.log \
		          --set-cell-number=100 \
		          --plot-prefix=LIBRARY \
		          --stdin=LIBRARY_R2.fq.gz \  ## R1 and R2 are swapped b.c. we customized our protocol
		          --stdout=LIBRARY_whitelist.txt

# Step 2: Wash whitelist
(implemented by scripts/wash_whitelist.py) 

# Step 3: Extract barcodes and UMIs and add to read names
umi_tools extract --bc-pattern=CCCCCCCCNNNNNNNN \
		        --log=extract.log \
		        --stdin=LIBRARY_R2.fq.gz \
		        --read2-in=LIBRARY_R1.fq.gz \
		        --stdout=LIBRARY_extracted.fq.gz \
		        --read2-stdout \
		        --filter-cell-barcode \
		        --error-correct-cell \
		        --whitelist=whitelist_washed.txt

# Step 4-0: Generate genome index
STAR --runThreadN 32 \
     --runMode genomeGenerate \
     --genomeDir /path/to/genome/index \
     --genomeFastaFiles /path/to/genome/fastas \
     --sjdbGTFfile /path/to/gtf \
     --sjdbOverhang 149

# Step 4-1: Map reads
STAR --runThreadN 32 \
     --genomeLoad LoadAndKeep \
     --genomeDir /path/to/genome/index \
     --readFilesIn LIBRARY_extracted.fq.gz \
     --readFilesCommand zcat \
     --outFilterMultimapNmax 1 \
     --outFilterType BySJout \
     --outSAMstrandField intronMotif \
     --outFilterIntronMotifs RemoveNoncanonical \
     --outFilterMismatchNmax 6 \
     --outSAMtype BAM SortedByCoordinate \
     --outSAMunmapped Within \
     --outFileNamePrefix LIBRARY_

# Step 4-2: Unload STAR genome
STAR --genomeLoad Remove \
     --genomeDir /path/to/genome/index

# Step 5-1: Assign reads to genes
featureCounts -s 1 \
	         -a annotation.gtf \
	         -o LIBRARY_gene_assigned \
	         -R BAM LIBRARY_Aligned.sortedByCoord.out.bam \
	         -T 32

# Step 5-2: Sort and index BAM file
sambamba sort -t 32 -m 64G \
              -o LIBRARY_assigned_sorted.bam \
		    LIBRARY_Aligned.sortedByCoord.out.bam.featureCounts.bam 

# Step 6: Count UMIs per gene per cell
umi_tools count --per-gene \
		      --per-cell \
		      --gene-tag=XT \
                --log={log} \
		      --stdin=LIBRARY_assigned_sorted.bam \
		      --stdout=LIBRARY_counts.tsv.gz

# Step 7: Append suffix to cells
(implemented by scripts/append_suffix.py)

# Step 8: Aggregate counts
zcat LIBRARY1_counts.tsv.gz LIBRARY2_counts.tsv.gz ... | gzip > outs/PROJECT_counts_all.tsv.gz
```

An abstracted workflow is illustrated in the graph below:

<p align="center">
  <img width="200"  src="https://github.com/RuiyuRayWang/ScRNAseq_smkpipe_at_Luolab/blob/main/rulegraph.svg">
</p>

## Acknowledgements

A large portion of this pipeline is inspired by [rna-seq-star-deseq2](https://github.com/snakemake-workflows/rna-seq-star-deseq2).
