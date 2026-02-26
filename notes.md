# Workshop Notes

## samples.csv demo ideas

- Add to workshop slides: a link to the live `data/samples.csv` URL on GitHub Pages
- **Basic prompt**: ask Claude questions about the samples in plain English (e.g. "how many embryo samples are there?", "which species have brain samples?")
- **Advanced prompt**: a one-shot prompt that generates a full UI sample explorer (interactive table, filters, etc.)

## R targets pipeline exercise — dataset

**Species**: *Anolis carolinensis* (green anole lizard)
**GEO accession**: GSE97367
**Paper**: Dosage compensation across tetrapods (multi-species)
**Design**: adult tissue RNA-seq, male vs female, 6 tissues (brain, heart, kidney, liver, ovary/testis), 3 reps/sex/tissue
**Data**: FPKM expression matrices directly downloadable from GEO via `GEOquery::getGEOSuppFiles("GSE97367")`
**Why**: real lizard data, confirmed counts on GEO, clean male vs female comparison, sex-biased gene expression — directly relevant; audience knows Anolis

> **Note on PRJNA699086** (bearded dragon ZW vs ZZ sex reversal): data is raw FASTQs only on SRA,
> no count matrix deposited. Supplementary files are DESeq2 result tables, not input counts.
> Would need full alignment pipeline to reuse — not suitable for a 20-min workshop slot.

### Basic prompt (interview pattern)

```
I want to build a targets pipeline in R to analyse some RNA-seq data.
Ask me 5–10 questions about my data and goals before writing any code.
```

Then follow up with:

```
The data is adult tissue RNA-seq from green anole lizards (Anolis carolinensis),
GEO accession GSE97367. I want to compare male vs female gene expression in
gonad tissue (ovary vs testis). Download the FPKM matrix with GEOquery,
run DESeq2, and produce a results table.
Use :: notation, base pipe |>, and tidyverse style.
```

### Advanced prompt (one-shot)

```
Create a complete R targets pipeline that:
1. Downloads the FPKM expression matrix for Anolis carolinensis from GEO
   accession GSE97367 using GEOquery::getGEOSuppFiles()
2. Filters to gonad samples (ovary vs testis, 3 reps each)
3. Runs DESeq2 comparing female (ovary) vs male (testis)
4. Plots a volcano plot of sex-biased genes, labelling the top 10 by adjusted p-value
5. Saves results table as CSV and plot as PNG

Use targets, DESeq2, GEOquery, ggplot2, ggrepel. Use :: notation throughout,
base pipe |>, set.seed(42). Include _targets.R, R/ scripts,
and exact install.packages() / BiocManager::install() calls needed.
```

## To resume

- [ ] Add the samples URL + prompts to the slides
- [ ] Write the basic plain-English Q&A prompt for samples.csv
- [ ] Write the advanced one-shot UI explorer prompt for samples.csv
- [ ] Add targets pipeline slide with GSE97367 prompts above
- [ ] Test that GEOquery::getGEOSuppFiles("GSE97367") returns the Anolis FPKM file cleanly
