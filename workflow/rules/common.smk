import os
import glob
import pandas as pd
from itertools import chain

# from snakemake.utils import validate

# validate(config, schema="../schemas/config.schema.yaml")

# ## Debug
# import yaml
# with open ('config/config_example.yaml') as f:
#     config = yaml.safe_load(f)

samples = (
    pd.read_csv(config["samples"], dtype={'User': str, 'Project': str, 'Sample': str, 'Library': str, 'File_R1': str, 'File_R2': str})
    # .set_index("Library", drop=False)
    # .sort_index()
)

## Parse sample table, auto-infer R1 R2 files if not specified
fq_r1_extensions = config['r1_extensions']
fq_r2_extensions = config['r2_extensions']
for index, row in samples.iterrows():
    tmp_dir = os.path.join("workflow", "data", row.User, row.Project, "fastqs", row.Library)
    if row.File_R1 not in os.listdir(tmp_dir):
        ## TODO: Check that globbed file number equals to 1
        samples.at[index,'File_R1'] = os.path.basename(list(chain(*[glob.glob(os.path.join(tmp_dir, fq_r1_ext)) for fq_r1_ext in fq_r1_extensions]))[0])
    if row.File_R2 not in os.listdir(tmp_dir):
        samples.at[index,'File_R2'] = os.path.basename(list(chain(*[glob.glob(os.path.join(tmp_dir, fq_r2_ext)) for fq_r2_ext in fq_r2_extensions]))[0])

# samples.Sample.fillna(samples.Library, inplace=True)

def parse_suffix(rule):
    # Given a rule name, return the suffix of its corresponding output file
    if rule == 'umi_tools_whitelist':
        return 'whitelist.txt'
    elif rule == 'wash_whitelist':
        return 'whitelist_washed.txt'
    elif rule == 'umi_tools_extract':
        return 'extracted.fq.gz'
    elif rule == 'STAR':
        return 'Aligned.sortedByCoord.out.bam'
    elif rule == 'featurecount':
        return 'Aligned.sortedByCoord.out.bam.featureCounts.bam'
    elif rule == 'sambamba_sort':
        return 'assigned_sorted.bam'
    elif rule == 'umi_tools_count':
        return 'counts_raw.tsv.gz'
    elif rule == "append_sfx":
        return 'counts.tsv.gz'

def get_files(rule):
    files = expand(
        '_'.join(["workflow/data/{user}/{project}/alignments/{library}/{library}", parse_suffix(rule)]),
        zip, user=samples.User.to_list(), project=samples.Project.to_list(), library=samples.Library.to_list()
        )
    return files

def parse_dynamic_output(rule):
    # all_out: list of all files supposed to be generated in a given rule
    # Parse a list of output files. If a file was already produced in past run, remove that file from list.
    # Used to prevent redundant jobs on later reruns.
    all_out = get_files(rule)
    out_files = []
    for f in all_out: 
        if not os.path.exists(f):
            out_files.append(f)
    return out_files

def get_fastqs(read):
    # Get input fastq read pairs from `samples` table
    if read=="R1":
        files = expand(
            "workflow/data/{user}/{project}/fastqs/{library}/{read}",
            zip, user=samples.User.to_list(), project=samples.Project.to_list(), library=samples.Library.to_list(), read=samples.File_R1.to_list()
            )
    elif read=="R2":
        files = expand(
            "workflow/data/{user}/{project}/fastqs/{library}/{read}",
            zip, user=samples.User.to_list(), project=samples.Project.to_list(), library=samples.Library.to_list(), read=samples.File_R2.to_list()
            )
    return files

def parse_STAR_dummy(wc):
    output = os.path.join("workflow", "data", wc.user, wc.project, "alignments", wc.library, wc.library) + "_Aligned.sortedByCoord.out.bam"
    if os.path.exists(output):
        return ""
    else:
        return "tmp/STARload.done"

def parse_fc_dummy(wc):
    output = os.path.join("workflow", "data", wc.user, wc.project, "alignments", wc.library, wc.library) + "_gene_assigned"
    if os.path.exists(output):
        return ""
    else:
        return "tmp/STARunload.done"

def get_aggr_output():
    return list(set(expand("workflow/data/{user}/{project}/outs/{project}_counts_all.tsv.gz", 
    zip, user=samples.User.to_list(), project=samples.Project.to_list())))