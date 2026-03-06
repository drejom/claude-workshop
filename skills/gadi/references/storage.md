# Gadi Storage Systems — Detailed Guide

## Storage at a Glance

```
/home/<inst>/<user>     10 GiB, backed up, not expandable
/scratch/<proj>/<user>  1 TiB default, fast, NO backup, files expire in 100 days
/g/data/<proj>/<user>   persistent, NO backup, accessible outside Gadi
$PBS_JOBFS              fast local SSD per job, DELETED at job end
massdata                tape archive, copyq access only
```

## /home

- Fixed 10 GiB per user, never expandable
- Best for: scripts, config files, SSH keys, small references
- Backed up — accidentally deleted files recoverable via `$HOME/.snapshot/`
- Do NOT use for: large data files, container images, conda environments, work data

## /scratch

- High-speed Lustre filesystem for active job I/O
- 1 TiB default; more available on request
- **Files not accessed for 100 days are quarantined; quarantined files deleted after 14 days**
  - Touch files periodically if keeping long-term: `find /scratch/ab12/$USER -exec touch {} \;`
  - Better: move completed results to `/g/data` or `massdata`
- Inode (file count) limit applies — check with `lquota`
- Need to be explicitly mounted in PBS jobs: `-l storage=scratch/ab12`

## /g/data

- Slower than /scratch but persistent (no expiry)
- Best for: completed analysis results, reference genomes, shared project data
- Also accessible from other NCI services (Nirin cloud, AARNet) without needing Gadi
- Inode limit applies — check with `lquota`
- Must be explicitly mounted: `-l storage=gdata/ab12`

## $PBS_JOBFS (local SSD)

- Ultra-fast NVMe SSD local to each compute node
- Default: 100 MB; request more with `-l jobfs=100GB` (max 400 GiB)
- **Completely deleted when the job finishes** (even if it fails)
- Best for: temporary files with heavy I/O, intermediate outputs, sort buffers
- Reduces load on shared Lustre filesystem — use it for tools that write many small files

```bash
# In your job script:
TMPDIR=$PBS_JOBFS
export TMPDIR

# ... run your tools that write to TMPDIR ...

# Before job ends, copy what you need:
cp $PBS_JOBFS/results/*.bam /scratch/ab12/$USER/output/
```

## massdata (Tape Archive)

- Long-term tape storage; data held in two separate buildings
- Only accessible from `copyq` jobs (not compute nodes or login nodes directly)
- Use `mdss` utility to interact:

```bash
mdss ls                           # list your massdata directory
mdss put file.tar ab12/archive/   # copy to massdata
mdss get ab12/archive/file.tar .  # retrieve from massdata
mdss mkdir ab12/archive/2024      # create directory
man mdss                          # full command reference
```

- Submit archive jobs as copyq jobs with `-l storage=massdata/ab12+scratch/ab12`
- Requests stage data from tape to disk cache first (can be slow — minutes to hours)

## Inode Management

**Inodes = number of files.** Both `/scratch` and `/g/data` have inode quotas per project.
Running out of inodes causes "no space left on device" errors even if storage space remains.

```bash
lquota                    # check your usage and limits
nci-files-report          # detailed breakdown by directory (run from login node)
```

**Conda is the main offender.** A single conda environment can contain 100,000+ files.
Alternatives:
- Use Singularity containers (one `.sif` file = all files)
- Use pre-installed modules (`module avail` — ~940 applications installed)
- Use Pixi: `module load pixi` — Rust-based, stores packages more efficiently
- Use `pip install --no-deps` into a small venv instead of full conda envs

**Singularity cache management:**
```bash
export SINGULARITY_CACHEDIR=/scratch/ab12/$USER/singularity-cache
singularity cache clean     # remove unused cached images
du -sh $SINGULARITY_CACHEDIR/*  # see what's there
```

## Data Transfer

Data-mover nodes (`gadi-dm.nci.org.au`) are optimised for high-speed transfers:

```bash
# From your laptop to Gadi (run on your laptop):
rsync -avP local_data/ username@gadi-dm.nci.org.au:/scratch/ab12/$USER/data/

# From Gadi to your laptop (run on your laptop):
rsync -avP username@gadi-dm.nci.org.au:/g/data/ab12/$USER/results/ ./local_results/

# Within Gadi (from login or data-mover node):
rsync -avP /scratch/ab12/$USER/results/ /g/data/ab12/$USER/results/
```

For large transfers, submit as a copyq job or use the data-mover nodes directly.
