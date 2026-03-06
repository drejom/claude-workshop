# Gadi Queue Reference

## Queue Selection Summary

| Queue | CPU architecture | CPUs/node | RAM/node | SU rate | Internet | Best for |
|-------|----------------|-----------|----------|---------|---------|---------|
| `normal` | Cascade Lake | 48 | 192 GiB | 1.0/CPU·hr | No | Standard bioinformatics jobs |
| `express` | Cascade Lake | 48 | 192 GiB | 3.0/CPU·hr | No | Quick testing (expensive!) |
| `normalbw` | Broadwell | 28 | 128–256 GiB | 0.75/CPU·hr | No | Cost-effective standard jobs |
| `expressbw` | Broadwell | 28 | 128–256 GiB | 2.25/CPU·hr | No | Broadwell testing |
| `normalsr` | Sapphire Rapids | 104 | 512 GiB | 2.0/CPU·hr | No | Newer, more cores/memory |
| `expresssr` | Sapphire Rapids | 104 | 512 GiB | 6.0/CPU·hr | No | Sapphire Rapids testing |
| `copyq` | Cascade Lake | 1 max | 192 GiB | 1.0/CPU·hr | **Yes** | Nextflow head, downloads, installs |
| `hugemem` | Cascade Lake | 48 | 1.5 TiB | 1.0/CPU·hr | No | Jobs needing >190 GiB RAM |
| `hugemembw` | Broadwell | 28 | 1 TiB | 0.75/CPU·hr | No | High-memory Broadwell jobs |
| `megamem` | Cascade Lake | 48 | 3 TiB | 1.0/CPU·hr | No | Very large memory assemblies |
| `gpuvolta` | Cascade Lake + V100 | 48 | 384 GiB | GPU pricing | No | GPU-accelerated tools |
| `dgxa100` | AMD EPYC + A100 | 128 | 2 TiB | GPU pricing | No | Specialised GPU work |
| `gpuhopper` | Xeon + H200 | 48 | 1 TiB | GPU pricing | No | Latest GPU nodes |
| `normalsl` | Skylake | 32 | 192 GiB | 0.7/CPU·hr | No | Older nodes, limited availability |

## Key Limits

- **`copyq`**: max 1 CPU, 6 nodes total; for anything needing internet (Nextflow, downloads, software builds)
- **`hugemem`**: max 192 CPUs (4 nodes); minimum 7 cores + 256 GiB requested
- **`megamem`**: max 96 CPUs; minimum 32 cores + 1.5 TiB
- **`normal`**: max 20,736 CPUs (exceptions by request)
- **`gpuvolta`**: max 960 CPUs / 80 GPUs; 4 GPUs per node

## Bioinformatics Queue Decision Guide

- **Short/small jobs** (<8 CPUs, <64 GiB): `normal` or `normalbw`
- **Standard alignment/variant calling**: `normal` (48 CPUs, 190 GiB typical request)
- **De novo assembly / metagenomics** (need lots of RAM): `hugemem` or `megamem`
- **Nextflow/nf-core head process**: `copyq` or persistent session
- **Downloading references / software**: login node (small) or `copyq` (large)
- **Deep learning / GPU basecalling (Dorado/Guppy)**: `gpuvolta`
- **Interactive R/Python exploration**: `qsub -I -q normal`
- **Quick script test before real run**: `express` (fast start, expensive SU)

## SU Calculation

SUs consumed = CPUs requested × walltime used (hours) × SU rate
- A 48-CPU normal job running for 2 hours = 96 SU
- Check allocation: `mybalance` or `nci_account -P <project>`
- Request only what you need; unused resources still consume SUs based on *requested* not *used*
