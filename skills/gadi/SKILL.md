---
name: nci-gadi
description: >
  Expert assistant for working on the NCI Gadi supercomputer (gadi.nci.org.au) at
  Australia's National Computational Infrastructure. Use this skill whenever the user
  is doing anything on Gadi or NCI: writing PBS job scripts, submitting or debugging
  qsub jobs, running bioinformatics pipelines (Nextflow, nf-core, Snakemake, custom),
  managing data on /scratch or /g/data, loading environment modules, setting up
  Singularity/Apptainer containers, running R or Python interactively or as batch jobs,
  or asking about NCI accounts, projects, queues, or storage allocations. Trigger on any
  mention of Gadi, NCI, qsub, PBS, /scratch, /g/data, nci.org.au, service units (SU),
  or Australian HPC/supercomputer work — even if the question seems simple.
---

# NCI Gadi HPC — Bioinformatics Assistant

You are an expert in running bioinformatics workflows on the NCI Gadi supercomputer.
Your users are bioinformaticians who are comfortable with Linux and R/Python but may be
newer to Gadi specifically. Help them write correct PBS scripts, troubleshoot job failures,
choose the right storage and queue, and set up software environments.

## The Single Most Important Thing

**Always declare storage explicitly.** Forgetting `-l storage=` is the #1 cause of
"file not found" errors on Gadi. Every filesystem your job touches (beyond
`/scratch/<project>`) must be listed:

```bash
#PBS -l storage=scratch/ab12+gdata/ab12
```

Valid filesystem identifiers: `scratch/<project>`, `gdata/<project>`, `massdata/<project>`.
All jobs implicitly have `scratch/<project>` for the running project, but nothing else.

---

## Storage Systems

| Path | Purpose | Limit | Notes |
|------|---------|-------|-------|
| `/home/<inst>/<user>` | Scripts, config | 10 GiB, **not expandable** | Backed up; use `$HOME/.snapshot` to recover |
| `/scratch/<proj>/<user>` | Active job I/O | 1 TiB default | No backup; files **deleted after 100 days** without access |
| `/g/data/<proj>/<user>` | Persistent results | Set by scheme | No backup; accessible outside Gadi (AARNet) |
| `$PBS_JOBFS` | Fast per-job SSD | 100 MB default, up to 400 GiB | **Deleted on job completion** — copy results out while job is running |
| `massdata` | Long-term tape archive | Set by scheme | Only accessible from `copyq` jobs |

**Inode (file count) limits apply to `/scratch` and `/g/data`.** Check usage with `lquota`.
Conda environments create millions of small files and rapidly exhaust inodes — prefer
Singularity containers, pre-installed modules, or Pixi/mamba with a shared cache.

**Navigation patterns:**
- Home: `/home/<institution>/<username>`
- Scratch: `/scratch/<project>/<username>`
- G/data: `/g/data/<project>/<username>`

---

## Queue Selection for Bioinformatics

| Queue | When to use | Key limits |
|-------|-------------|-----------|
| `normal` | Standard CPU jobs (alignment, variant calling, etc.) | 48 CPUs / 190 GiB typical; max 20736 CPUs |
| `normalbw` | Same but Broadwell nodes (cheaper per SU) | 28 CPUs / 128–256 GiB per node |
| `normalsr` | Sapphire Rapids (newer, faster, 2 SU/CPU·hr) | 104 CPUs / 512 GiB per node |
| `copyq` | **Anything needing internet** (Nextflow head job, large downloads, software installs) | 1 CPU max; 6 nodes |
| `hugemem` | Large-memory jobs (>190 GiB) | 48 CPUs / 1.5 TiB Optane per node |
| `gpuvolta` | GPU jobs (deep learning, GPU-accelerated tools) | 4× V100 32 GB per node |
| `express` / `expresssr` | Quick testing/debugging (3–6× SU cost) | Use sparingly |

**Internet access is only available on `copyq` nodes.** This is critical for Nextflow.

See `references/queues.md` for full queue specs and SU charge rates.

---

## PBS Job Script — Bioinformatics Template

```bash
#!/bin/bash
#PBS -N my_job
#PBS -P ab12                        # your NCI project code
#PBS -q normal                      # queue
#PBS -l ncpus=8
#PBS -l mem=32GB
#PBS -l walltime=04:00:00
#PBS -l jobfs=50GB                  # fast local SSD (optional, good for temp files)
#PBS -l storage=scratch/ab12+gdata/ab12   # ALL filesystems you'll access
#PBS -l wd                          # start in submission directory
#PBS -o logs/job.o
#PBS -e logs/job.e

# Load modules
module load samtools/1.18
module load bwa/0.7.17

# Use $PBS_JOBFS for temp files (fast, avoids inode pressure on /scratch)
TMPDIR=$PBS_JOBFS
export TMPDIR

# Run your tool
bwa mem -t $PBS_NCPUS ref.fa reads_R1.fq reads_R2.fq | \
  samtools sort -@ $PBS_NCPUS -o /scratch/ab12/$USER/output/sample.bam

# Copy results from jobfs back to scratch before job ends
# cp $PBS_JOBFS/results/* /scratch/ab12/$USER/output/
```

**Key PBS directives reference:**

| Directive | Meaning |
|-----------|---------|
| `-P <code>` | Project to charge SUs to |
| `-q <queue>` | Queue name |
| `-l ncpus=N` | CPU cores (default: 1) |
| `-l mem=XGB` | Total RAM (default: **500 MiB** — always set this!) |
| `-l walltime=HH:MM:SS` | Time limit — job killed if exceeded |
| `-l storage=...` | Filesystems needed (see above) |
| `-l jobfs=XGB` | Local SSD on compute node (default: 100 MB) |
| `-l wd` | Start job in submission directory |
| `-l ngpus=N` | GPUs (for gpuvolta queue) |
| `-j oe` | Merge stdout + stderr into one file |
| `-W depend=afterok:JOBID` | Run after another job completes successfully |

Full reference: `references/pbs-directives.md`

---

## Environment Modules

```bash
module avail <name>          # search available versions
module avail samtools        # e.g., list samtools versions
module load samtools/1.18    # load specific version (always pin the version)
module list                  # show currently loaded modules
module unload <name>         # unload a module
module purge                 # unload all modules
module show <name>/<ver>     # show what a module sets up
```

**Always pin module versions** (e.g., `samtools/1.18` not just `samtools`) to avoid
silent breakage when NCI updates the default. Modules auto-load their dependencies.

Common bioinformatics modules on Gadi: `samtools`, `bwa`, `star`, `gatk`, `bcftools`,
`python3`, `R`, `nextflow`, `singularity`, `java`, `trimmomatic`, `fastqc`, `multiqc`.
Check current availability with `module avail <tool>` on a login node.

---

## Nextflow / nf-core on Gadi

**Critical:** Gadi compute nodes have no external internet. Nextflow's head process
must run somewhere with network access.

### Option 1: Persistent session (recommended for long pipelines)

```bash
# On a login node:
persistent-sessions start -p ab12 my-pipeline

# Connect to it:
ssh my-pipeline.<username>.ab12.ps.gadi.nci.org.au

# Inside the session, load and run:
module load nextflow/23.10.0
module load singularity

nextflow run nf-core/rnaseq \
  -profile singularity,nci_gadi \
  --input samplesheet.csv \
  --outdir /g/data/ab12/$USER/results \
  -resume
```

### Option 2: copyq job (for shorter runs or testing)

```bash
#!/bin/bash
#PBS -N nf-rnaseq
#PBS -P ab12
#PBS -q copyq
#PBS -l ncpus=1
#PBS -l mem=8GB
#PBS -l walltime=10:00:00
#PBS -l storage=scratch/ab12+gdata/ab12
#PBS -l wd

module load nextflow/23.10.0
module load singularity

export NXF_SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
export NXF_WORK=/scratch/ab12/$USER/nf-work

nextflow run nf-core/rnaseq \
  -profile singularity,nci_gadi \
  --input samplesheet.csv \
  --outdir /g/data/ab12/$USER/results \
  -resume
```

**Important nf-core/nci_gadi config notes:**
- The `nci_gadi` profile auto-submits tasks as PBS jobs and handles queue selection
- `$PROJECT` env var sets the billing project — confirm if you belong to multiple projects
- Set `NXF_SINGULARITY_CACHEDIR` on `/scratch` to avoid re-pulling containers
- Resource usage is logged per-task in `gadi-nf-core-joblogs.tsv` for SU accounting

---

## Singularity Containers for R and Python

Singularity is the container runtime on Gadi (no Docker). Images can be pulled from
Docker Hub (on copyq/login nodes), or pre-built and cached.

```bash
module load singularity

# Pull a Docker image (needs network — do on login node or copyq)
singularity pull --dir /scratch/ab12/$USER/sif docker://rocker/tidyverse:4.3.1

# Run an R script inside a container in a PBS job
singularity exec /scratch/ab12/$USER/sif/tidyverse_4.3.1.sif \
  Rscript my_analysis.R

# Run a Python script
singularity exec docker://python:3.11-slim python my_script.py

# Interactive R session in a job (qsub -I, then):
singularity shell /scratch/ab12/$USER/sif/tidyverse_4.3.1.sif
```

**SIF cache:** Point `SINGULARITY_CACHEDIR` to `/scratch` (not `/home`, which has a
10 GiB limit). Pull images once, reuse across jobs.

```bash
export SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
```

---

## Interactive Jobs

Use interactive jobs for testing, debugging, and exploratory analysis with R/Python.
Never run compute-intensive work on login nodes (30-min / 4 GiB limit).

```bash
# Basic interactive job
qsub -I -q normal -P ab12 \
  -l walltime=02:00:00,ncpus=4,mem=16GB,storage=scratch/ab12+gdata/ab12,wd

# GPU interactive job
qsub -I -q gpuvolta -P ab12 \
  -l walltime=01:00:00,ncpus=12,ngpus=1,mem=48GB,jobfs=100GB,storage=scratch/ab12+gdata/ab12,wd
```

Your prompt changes to `[username@gadi-<nodetype>-XXXX ~]$` when the job starts.
Type `exit` to end the interactive session.

---

## Job Submission and Monitoring

```bash
qsub job.sh                      # submit a job → returns JOBID (e.g., 12345678.gadi-pbs)
qstat -swx <jobID>               # check job status (queue position, runtime, node)
qstat -fx <jobID> | less         # full job details
nqstat_anu <jobID>               # CPU and memory utilisation (run this ~10 min after start)
qps <jobID>                      # snapshot of running processes inside the job
qls <jobID>                      # list files in $PBS_JOBFS
qcat -o <jobID>                  # view STDOUT of running job
qcat -e <jobID>                  # view STDERR of running job
qdel <jobID>                     # cancel a job
qstat -u $USER -Esw              # list all your jobs
```

**Don't query more than once every 10 minutes** — excessive `qstat` polling is treated
as an attack on the scheduler.

Output files appear in the working directory as `<jobname>.o<jobID>` and `<jobname>.e<jobID>`.
Always check both after a job finishes.

---

## Common Gotchas and Troubleshooting

**"file not found" / "no such file"**
→ Almost always a missing `-l storage=` directive. Add the relevant `scratch/<proj>` or `gdata/<proj>`.

**Job killed immediately / exit code 271**
→ Job used more memory than requested. Increase `-l mem=`.

**Job killed at exactly walltime**
→ Job timed out. Increase `-l walltime=` or use `-resume` (Nextflow) to restart.

**"Permission denied" on project directory**
→ You need to be connected to the project in MyNCI and wait ~15 min for permissions to propagate.

**Nextflow tasks never start / all pending**
→ Check that the head job is on `copyq` or a persistent session (not a compute node).
→ Also check that `$PROJECT` is set correctly.

**Conda inode exhaustion**
→ Prefer Singularity containers or pre-installed modules. If you must use conda,
create environments in `/g/data` (not `/home` or `/scratch`) and use `conda clean -a` regularly.
Consider Pixi (`module load pixi`) as a lower-inode alternative.

**Login node job killed (>30 min or >4 GiB)**
→ Submit as a proper PBS job or use an interactive job (`qsub -I`).

**Module conflict**
→ Run `module purge` then reload only what you need, or use `module unload <app>` first.

---

## Useful Commands

```bash
lquota                           # check storage and inode usage for your projects
nci-files-report                 # detailed breakdown of who is using /scratch or /g/data
mybalance                        # check remaining SU allocation
nci_account -P ab12              # project allocation details
ls /apps/<toolname>              # see installed versions of a tool
```

---

## Reference Files

- `references/queues.md` — full queue specifications and SU rates
- `references/pbs-directives.md` — complete PBS directive reference
- `references/storage.md` — detailed storage system guide
- `references/nextflow-nci.md` — Nextflow/nf-core Gadi configuration details
