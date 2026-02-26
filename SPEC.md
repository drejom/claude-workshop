# Claude Code Workshop — Spec & Scope

## Overview

A practical workshop on Claude Code for ecology and genomics researchers at the University of Canberra, delivered via Zoom. Audience has hands-on laptops and their own Anthropic API accounts.

**Audience**: Ecologists and genomicists (primarily reptile/sex determination research). ~70% basic to intermediate Claude Code users — some already running R scripts, some with HPC usage. Skip the basics; go straight to power features.

**Format**: ~20-minute slide presentation → hands-on exercises

**Delivery**: Zoom, attendees code along. Pre-requisite: Anthropic API key set up before the session.

---

## Repository Structure (planned)

```
claude-workshop/
├── SPEC.md                     ← this file
├── README.md                   ← setup checklist (API key, npm install, clone repo)
├── slides/
│   └── ...                     ← slide deck source (Quarto or Reveal.js, TBD)
├── exercises/
│   ├── 01-excel-queries/       ← natural language queries on sample data
│   ├── 02-r-targets-pipeline/  ← build a targets workflow with Claude Code
│   └── 03-gadi-crescendo/      ← (optional/advanced) HPC job submission on NCI Gadi
├── data/
│   └── samples.xlsx            ← reptile sample database export (field data)
├── skills/
│   └── gadi/                   ← custom Claude Code skill built from NCI Gadi docs
├── .claude/
│   └── commands/               ← example custom slash commands for bioinformatics
└── assets/
    └── icons/                  ← SVG icons for slide features (MDI/Lucide style)
```

---

## Slide Deck Outline

**Target: ~10 slides, 20 minutes**

| # | Slide | Notes |
|---|-------|-------|
| 1 | **Title** | "Claude Code: Power Features for Research Workflows". Denis O'Meally, UC. |
| 2 | **Where Claude Code fits** | Graphical abstract — scope of domains. Not just coding; it's a research automation layer. |
| 3 | **Why this audience** | Pain points they know: parsing datasets, building pipelines, HPC friction. Claude Code as glue. |
| 4 | **Power Features — Slide A** | 6 features: MCP, Custom Slash Commands, Sub-agents, Extended Thinking, Planning Mode, "Interview Me" |
| 5 | **Power Features — Slide B** | 6 features: CLAUDE.md, Headless/HPC Mode, Hooks, Context Management, GitHub Integration, Session Resume |
| 6 | **Live demo arc** | Preview the three exercises: Excel → R pipeline → Gadi crescendo |
| 7 | **Pre-workshop checklist** | Install Claude Code, get API key, set env var, clone repo |
| 8 | **Questions before we code?** | Open floor |

> **Note**: Slides 4 and 5 replace the earlier outline's slides on MCP, bioinformatics MCPs, and Planning Mode (previously slides 4, 5, 7). The 12-feature content is the main technical payload.

---

## Power Features: 12 Features Across Two Slides

Each feature gets: a concise one-liner, an SVG icon (3 options per feature in MDI/Lucide style), and a paragraph Denis expands on verbally.

### Slide A — Expanding what Claude Code can do

| # | Feature | One-liner | Icon concept |
|---|---------|-----------|-------------|
| 1 | **MCP Servers** | Plug Claude into databases, APIs, Slack, GitHub via universal protocol | USB-C plug / network nodes / server rack |
| 2 | **Custom Slash Commands** | Save lab workflows as reusable `/project:variant-qc` commands | Terminal prompt / bookmark / command palette |
| 3 | **Sub-agents** | Claude spawns parallel agents for simultaneous tasks | Fork/branch / parallel lanes / multi-person team |
| 4 | **Extended Thinking** | `think` → `think harder` → `ultrathink` for deeper reasoning | Brain with layers / thought bubble stack / CPU |
| 5 | **Planning Mode** | Shift+Tab to review strategy before execution | Blueprint / checklist / map with route |
| 6 | **"Interview Me"** | Ask Claude to gather requirements before coding | Vintage microphone / speech bubbles / Q&A |

### Slide B — Workflow, automation, and context

| # | Feature | One-liner | Icon concept |
|---|---------|-----------|-------------|
| 7 | **CLAUDE.md** | Persistent project memory with hierarchical overrides | Memory chip / layered files / bookmark |
| 8 | **Headless Mode** | `-p` flag embeds Claude in SLURM batch jobs and CI | Cluster nodes / script / robot |
| 9 | **Hooks** | Auto-run linting, notifications, logging on Claude's actions | Hook/anchor / event chain / trigger |
| 10 | **Context Management** | `/compact` and `/clear` for long productive sessions | Compress / broom sweep / sliding window |
| 11 | **GitHub Integration** | Full PR lifecycle from natural language | Octocat / git branch / pull request |
| 12 | **Session Resume** | `--continue` / `--resume` survives SSH drops | SSH terminal / resume play / bookmark |

---

## SVG Icons Task

3 icon options per feature (24 total icons × 2 = nope, 12 features × 3 options = 36 SVGs).

- Style: MDI / Lucide — minimalist, single-colour, ~24×24 viewBox, stroke-based
- Delivered as individual `.svg` files in `assets/icons/`
- Naming: `feature-<slug>-<option>.svg`, e.g. `feature-mcp-plug.svg`, `feature-mcp-network.svg`, `feature-mcp-server.svg`

**Status**: Not yet created. To be built as part of this repo.

---

## Exercises

### Exercise 1 — Excel data queries (warm-up, ~15 min)

- Data: `data/samples.xlsx` — reptile field sample database export
- Task: Use Claude Code to answer natural language questions about the data without writing SQL or Python manually
- Example prompts: "show me sex ratios by species", "which locations have the most samples", "are there any outlier body size measurements?"
- Goal: the "wow, this is easy" moment

### Exercise 2 — R targets pipeline (~20 min)

- Task: Use Claude Code to scaffold a reproducible `targets` pipeline for a simple genomics analysis
- Demonstrate `auto_document()` and `tar_make()`
- Goal: show Claude Code as a co-pilot for reproducible research pipelines

### Exercise 3 — Gadi crescendo (optional/advanced, time permitting)

- Task: Use the custom Gadi skill to have Claude Code write and submit an HPC job
- Prerequisite: NCI Gadi credentials (Denis sorts separately)
- Goal: "this changes my entire workflow" moment
- Fallback: show a pre-run result + the generated job script if live submission isn't feasible on the day

---

## Custom Gadi Skill

NCI Gadi documentation is well-maintained and mostly in Markdown/HTML. The plan:

1. Scrape/export relevant Gadi docs (job submission, partitions, software modules, storage, PBS/SLURM syntax)
2. Build a custom Claude Code skill from that content
3. Demonstrate: without skill → Claude guesses; with skill → Claude writes correct Gadi job scripts first time

This is also used as a live example of **how to build a skill** — the methodology is the lesson, not just the output.

---

## Delivery Infrastructure

- **GitHub repo**: source of truth — exercises, data, skills, CLAUDE.md examples
- **GitHub Pages site**: reference hub with pre-workshop checklist, slide links, exercise instructions
- **Pre-workshop checklist** (to go on GitHub Pages):
  - [ ] Install Node.js (v18+)
  - [ ] `npm install -g @anthropic-ai/claude-code`
  - [ ] Create Anthropic API key at console.anthropic.com
  - [ ] `export ANTHROPIC_API_KEY=sk-ant-...` (add to shell profile)
  - [ ] Clone the workshop repo
  - [ ] Verify: `claude --version`

> **Important note for invitations**: Claude Code works with a Pro or Max subscription (`claude login`) or with Anthropic API credits (`ANTHROPIC_API_KEY`).

---

## Open Questions / TODOs

- [ ] Confirm database connection details (PostgreSQL or MySQL) for optional live DB exercise
- [ ] Get NCI Gadi credentials sorted before workshop
- [ ] Decide slide format: Quarto (`.qmd` → Reveal.js) vs plain Reveal.js vs Google Slides
- [ ] Create SVG icons (36 total, MDI/Lucide style)
- [ ] Source/clean `samples.xlsx` reptile data
- [ ] Build Gadi skill from NCI docs
- [ ] Set up GitHub Pages site
- [ ] Do a dry-run on Gadi the day before

---

*Last updated: 2026-02-24. Brainstormed from `background_notes/claude_brain-dump.md`.*
