# Nextflow / nf-core on NCI Gadi

## The Fundamental Constraint

**Gadi compute nodes have no external internet access.** Nextflow's head process must
download container images, resolve pipeline code, and communicate with external services
— so it cannot run as a regular PBS job on compute nodes.

**Two solutions:**

1. **Persistent session** — a lightweight always-on session on Gadi's infrastructure
   (recommended for multi-day pipelines)
2. **copyq job** — a PBS job on the 6 internet-enabled copyq nodes
   (fine for shorter runs; max 1 CPU, time-limited)

---

## Setting Up a Persistent Session

```bash
# Start (from login node)
persistent-sessions start -p ab12 my-pipeline
# → prints: session running - connect using ssh my-pipeline.<user>.ab12.ps.gadi.nci.org.au

# Connect
ssh my-pipeline.<user>.ab12.ps.gadi.nci.org.au

# Inside the session: load modules and run Nextflow
module load nextflow/23.10.0
module load singularity

# Set up caches on /scratch (NOT /home — 10 GiB limit will fill fast)
export NXF_SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
export NXF_WORK=/scratch/ab12/$USER/nf-work
mkdir -p $NXF_SINGULARITY_CACHEDIR $NXF_WORK

nextflow run nf-core/rnaseq \
  -profile singularity,nci_gadi \
  --input /scratch/ab12/$USER/samplesheet.csv \
  --genome GRCh38 \
  --outdir /g/data/ab12/$USER/rnaseq-results \
  -resume
```

**Persistent session notes:**
- Sessions are only visible from within Gadi (not from your laptop)
- They are lightweight — do not run compute inside them, only workflow managers
- List sessions: `persistent-sessions list`
- Keep qstat polling to ≤ once per 10 minutes inside Nextflow to avoid scheduler abuse
- Sessions are currently free (no SU charge) but closely monitored

---

## Running Nextflow via copyq Job

```bash
#!/bin/bash
#PBS -N nf-rnaseq
#PBS -P ab12
#PBS -q copyq
#PBS -l ncpus=1
#PBS -l mem=8GB
#PBS -l walltime=48:00:00
#PBS -l storage=scratch/ab12+gdata/ab12
#PBS -l wd

module load nextflow/23.10.0
module load singularity

export NXF_SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
export NXF_WORK=/scratch/ab12/$USER/nf-work

nextflow run nf-core/rnaseq \
  -profile singularity,nci_gadi \
  --input samplesheet.csv \
  --genome GRCh38 \
  --outdir /g/data/ab12/$USER/rnaseq-results \
  -resume
```

---

## The nci_gadi Profile

The `nci_gadi` profile (from [nf-core/configs](https://github.com/nf-core/configs)) handles:
- Submitting each Nextflow task as a separate PBS job
- Queue selection based on resource requirements:
  - < 128 GiB → `normalbw`
  - 128–190 GiB → `normal`
  - > 190 GiB → `hugemembw`
- Charging to `$PROJECT` (the environment variable; set correctly if you belong to multiple projects)
- Resource accounting in `gadi-nf-core-joblogs.tsv`

**Activate with:**
```bash
nextflow run nf-core/<pipeline> -profile singularity,nci_gadi
```

---

## Singularity Image Cache

Container images are large (~1–5 GiB each). Always cache them on `/scratch`:

```bash
export SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
export NXF_SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
```

Pre-pull images on a login node or copyq:
```bash
module load singularity
singularity pull --dir $SINGULARITY_CACHEDIR docker://nfcore/rnaseq:3.13.2
```

---

## Checking Which Project is Being Used

```bash
echo $PROJECT       # shows current default project
nci_account -P ab12 # shows allocation and balance for project ab12
mybalance           # shows all your project balances
```

If you belong to multiple projects, set `$PROJECT` explicitly in your job or session:
```bash
export PROJECT=ab12
```

---

## Common nf-core Pipelines on Gadi

| Pipeline | Use case | Typical resources |
|----------|---------|-----------------|
| `nf-core/rnaseq` | Bulk RNA-seq (STAR/Salmon) | 16–48 CPUs, 64–190 GiB per task |
| `nf-core/sarek` | Germline/somatic variant calling | 16–48 CPUs, 64–190 GiB |
| `nf-core/taxprofiler` | Metagenomic classification | 8–48 CPUs |
| `nf-core/ampliseq` | 16S/amplicon analysis | 8–16 CPUs |
| `nf-core/methylseq` | Bisulfite sequencing | 16–48 CPUs |
| `nf-core/chipseq` | ChIP-seq / ATAC-seq | 8–48 CPUs |

Check https://nf-co.re for current pipeline list and samplesheet formats.

---

## Troubleshooting Nextflow on Gadi

**Tasks stay PENDING forever**
- Head job must be on `copyq` or persistent session (not compute nodes)
- Check `echo $PROJECT` matches your allocation
- Check storage directive includes all paths in the pipeline's work dir

**"SIGTERM or SIGKILL" in task log**
- Task exceeded memory or walltime; add `process { memory = '64 GB' }` in nextflow.config
- Or use `--max_memory` / `--max_cpus` pipeline params

**Singularity image pull fails**
- Run on login node or copyq (needs internet)
- Check `SINGULARITY_CACHEDIR` is on `/scratch` not `/home`

**Resume not working**
- Must point `NXF_WORK` to same directory as original run
- Check `.nextflow.log` for cache-miss reasons

**"Too many open files"**
- Increase `ulimit -n` in your session or job script
- Or reduce `--max_forks` in nextflow.config
