# Workshop Notes

## samples.csv demo ideas

- Add to workshop slides: a link to the live `data/samples.csv` URL on GitHub Pages
- **Basic prompt**: ask Claude questions about the samples in plain English (e.g. "how many embryo samples are there?", "which species have brain samples?")
- **Advanced prompt**: a one-shot prompt that generates a full UI sample explorer (interactive table, filters, etc.)

## R targets pipeline exercise — dataset

**Species**: *Anolis carolinensis* (green anole lizard)
**GEO accession**: GSE291397
**Paper**: Artificial Light at Night Disrupts Circadian and Metabolic Gene Expression in the Green Anole Lizard
**Design**: adult RNA-seq, 12 males + 12 females, 6 tissues (brain, liver, dorsal skin, ventral skin, gonad, eye), 3 treatments (Midday control / Midnight / ALAN), n=4 per sex per treatment
**Data**: `GSE291397_GA_raw_counts_FINAL.csv.gz` (6.4 Mb) — raw integer counts confirmed on GEO
**Method**: limma-voom (integer counts; voom confirmed working end-to-end)
**Status**: TESTED ✓ — 16,836 genes pass filterByExpr; 13,348 DE FDR<0.05 (Ovary vs Testes, as expected)

### Key metadata facts (confirmed by test run)

- Tissue labels: `Ovary` (Female) and `Testes` (male) — separate values, not "Gonad"
- Sex labels: `Female` / `male` (inconsistent case in GEO metadata — handle in code)
- Library names in count matrix cols (e.g. `33TA`) match `description` field in pData as `"Library name: 33TA"`
- Count matrix cols 1–5 are annotation (Chr, Start, End, Strand, Length) — skip these

### Basic prompt (interview pattern)

```
I want to build a targets pipeline in R to analyse some RNA-seq data.
Ask me 5–10 questions about my data and goals before writing any code.
```

Then follow up with:

```
The data is adult tissue RNA-seq from green anole lizards (Anolis carolinensis),
GEO accession GSE291397. I want to compare ovary vs testes gene expression using
the Midday control samples (4 reps each). Download the raw count matrix with
GEOquery, fetch sample metadata, run limma-voom, and produce a results table.
Use :: notation, base pipe |>, and tidyverse style.
```

### Advanced prompt (one-shot)

```
Create a complete R targets pipeline that:
1. Downloads raw count matrix GSE291397_GA_raw_counts_FINAL.csv.gz from GEO
   accession GSE291397 using GEOquery::getGEOSuppFiles()
2. Downloads sample metadata using GEOquery::getGEO("GSE291397")
3. Filters to Midday control samples, tissue "Ovary" (Female) and "Testes" (male),
   4 replicates each; matches library names from pData description field to count cols
4. Runs limma-voom comparing Female (Ovary) vs Male (Testes)
5. Plots a volcano plot labelling the top 15 DE genes by adjusted p-value
6. Saves results table as CSV and volcano plot as PNG

Use targets, limma, edgeR, GEOquery, ggplot2, ggrepel, dplyr.
Use :: notation throughout, base pipe |>, set.seed(42).
Include _targets.R, R/ scripts, and exact BiocManager::install() calls needed.
```

> **Datasets ruled out:**
> - GSE97367 (*Anolis*, dosage compensation): summary FPKM only — 1 value per tissue/sex, no replicates
> - PRJNA699086 (*Pogona vitticeps*, ZW vs ZZ sex reversal): raw FASTQs on SRA only, no count matrix on GEO

## To resume

- [ ] Add the samples URL + prompts to the slides
- [ ] Write the basic plain-English Q&A prompt for samples.csv
- [ ] Write the advanced one-shot UI explorer prompt for samples.csv
- [ ] Add targets pipeline slide with GSE291397 prompts above
