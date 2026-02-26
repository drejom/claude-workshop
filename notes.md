# Workshop Notes

## samples.csv demo ideas

- Add to workshop slides: a link to the live `data/samples.csv` URL on GitHub Pages
- **Basic prompt**: ask Claude questions about the samples in plain English (e.g. "how many embryo samples are there?", "which species have brain samples?")
- **Advanced prompt**: a one-shot prompt that generates a full UI sample explorer (interactive table, filters, etc.)

## R targets pipeline exercise — dataset

**Species**: *Pogona vitticeps* (central bearded dragon)
**BioProject**: PRJNA699086
**Paper**: [PLOS Genetics 2021](https://journals.plos.org/plosgenetics/article?id=10.1371/journal.pgen.1009465)
**Design**: embryonic gonad RNA-seq, ZW females vs ZZ sex-reversed females, 3 developmental stages (6, 12, 15), ~39 samples
**Why**: bearded dragon TSD+GSD in one species — directly relevant audience; clean two-group comparison; key genes (FOXL2, AMH, SOX9, ESR2) are names this audience knows

### Basic prompt (interview pattern)

```
I want to build a targets pipeline in R to analyse some RNA-seq data.
Ask me 5–10 questions about my data and goals before writing any code.
```

Then follow up with:

```
The data is gonad RNA-seq from bearded dragon embryos (Pogona vitticeps),
BioProject PRJNA699086. I want to compare ZW females vs ZZ sex-reversed females
at developmental stage 6. Run DESeq2 and produce a results table.
Use :: notation, base pipe |>, and tidyverse style.
```

### Advanced prompt (one-shot)

```
Create a complete R targets pipeline that:
1. Downloads count data from BioProject PRJNA699086 using the SRAdb or GEOquery package
2. Filters to developmental stage 6 samples (ZW female vs ZZ sex-reversed female)
3. Runs DESeq2 comparing the two groups
4. Plots a volcano plot highlighting FOXL2, AMH, and SOX9
5. Saves results table as CSV and volcano plot as PNG

Use targets, DESeq2, ggplot2, ggrepel. Use :: notation throughout,
base pipe |>, set.seed(42). Include _targets.R, R/ scripts,
and exact install.packages() / BiocManager::install() calls needed.
```

## To resume

- [ ] Add the samples URL + prompts to the slides
- [ ] Write the basic plain-English Q&A prompt
- [ ] Write the advanced one-shot UI explorer prompt
- [ ] Add targets pipeline slide with PRJNA699086 prompts above
- [ ] Verify count data is accessible via GEOquery/SRAdb before workshop
