# 12 Claude Code power features for research workshops

**Claude Code's most valuable capabilities for researchers go far beyond simple script generation.** The features below — organized as two slides of six — represent the highest-impact tools for ecologists, genomicists, and HPC-cluster users who already handle basic tasks. Each feature includes concrete research examples, a sense of how well-known it is, and the specific syntax needed to use it. These 12 were selected to progress from "wow, I didn't know it could do that" to "this changes my entire workflow."

---

## Slide 1: Expanding what Claude Code can do

### 1. MCP servers connect Claude Code to your research infrastructure

**Model Context Protocol (MCP)** is an open standard Anthropic released in November 2024 that lets Claude Code talk directly to databases, APIs, file systems, and communication tools through a universal plug-in architecture. Think of it as USB-C for AI — one protocol, many connections. Claude Code acts as an MCP client; lightweight MCP servers expose tools Claude can call during a session.

**Configuration** is straightforward. Add servers via the CLI or a project-level `.mcp.json` file:

```bash
# Add a PostgreSQL server for your variant database
claude mcp add genome-db -- npx -y @modelcontextprotocol/server-postgres \
  "postgresql://analyst:pw@db-server:5432/variants_db"

# Add filesystem access to HPC scratch space
claude mcp add hpc-data -- npx -y @modelcontextprotocol/server-filesystem \
  /scratch/lab/genomics_project
```

The `.mcp.json` file can be committed to git so your entire lab shares the same configuration. Servers run locally via stdio or remotely via SSE (Server-Sent Events). Scoping works at two levels: `--scope project` (stored in `.mcp.json`, shared) or `--scope user` (stored in `~/.claude/`, personal).

**Research-relevant servers** include PostgreSQL and SQLite (query specimen or variant databases directly), GitHub/GitLab (manage pipeline repos), Google Drive (access shared protocols and data dictionaries), Slack (post results to lab channels), Filesystem (navigate large HPC directory trees), Brave Search and Fetch (look up gene annotations or access NCBI/UniProt). The full ecosystem lives at **github.com/modelcontextprotocol/servers** and community directories like **mcp.so**.

**The killer use case for researchers**: a genomicist could ask Claude Code to "query our variants database for all high-confidence SNPs in BRCA2 from the latest batch, write a summary report, and post it to the #results Slack channel" — and Claude would execute all three steps using the configured MCP servers. You can also **write custom MCP servers in Python** that wrap SLURM commands, Nextflow triggers, or bioinformatics APIs. This feature is **well-known among developers but significantly underused by researchers**, making it a high-impact workshop topic.

### 2. Custom slash commands encode your lab's workflows

Custom commands (also called "custom skills") let you save reusable, parameterized prompt templates as Markdown files that become slash commands inside Claude Code. They turn complex, domain-specific workflows into one-line invocations.

**Setup** requires creating Markdown files in specific directories:

- **Project commands**: `.claude/commands/<name>.md` → invoked as `/project:<name>`
- **User commands**: `~/.claude/commands/<name>.md` → invoked as `/user:<name>`

Each file contains the prompt template with an optional **`$ARGUMENTS`** placeholder for dynamic input. A bioinformatics example:

```markdown
<!-- .claude/commands/variant-qc.md -->
Run quality control on the variant call set: $ARGUMENTS

QC Pipeline:
1. Check VCF file integrity with bcftools
2. Calculate Ti/Tv ratio and check missingness per sample
3. Generate allele frequency spectrum
4. Flag variants failing Hardy-Weinberg (p < 1e-6)
5. Produce QC summary report in markdown
6. Save filtered VCF to results/filtered/
```

Invoked as: `/project:variant-qc batch_042_merged.vcf.gz`

Other high-value examples for researchers include commands for submitting SLURM jobs with standard lab headers, formatting manuscripts for specific journals, running species diversity analyses, or generating reproducible R scripts with proper seed-setting and package version logging. Project-level commands commit to git so the whole lab benefits. **This is a genuine hidden gem** — most Claude Code users rely solely on CLAUDE.md and don't realize parameterized commands exist. The difference from CLAUDE.md is important: CLAUDE.md provides always-on context (consuming tokens every session), while custom commands fire only when invoked.

### 3. Sub-agents let Claude parallelize complex research tasks

Claude Code can spawn independent **sub-agents** via its built-in **Task tool**. Each sub-agent runs in its own context window with access to the same filesystem and tools, executes independently, and returns results to the parent agent for synthesis.

**How it works technically**: when Claude Code encounters a task that benefits from decomposition, it creates sub-agent instances with focused instructions. Each sub-agent has its own tool-use loop — it can read/write files, run bash commands, and search code independently. The parent agent coordinates results when sub-agents complete. Sub-agents share the filesystem but **not** conversation context, which prevents interference.

**Research examples where this shines**:

- Ask Claude to "explore both a random forest and gradient boosting approach to this species classification problem" — two sub-agents work in parallel
- "Write the data preprocessing script AND the visualization code simultaneously"
- Complex pipeline debugging where one agent traces data flow while another examines log files
- Multi-file refactoring across an analysis codebase

Users can trigger sub-agents organically (Claude decides to parallelize) or explicitly: "use sub-agents to handle the data cleaning and the statistical analysis in parallel." The Task tool is **enabled by default** and inherits parent permission settings. This feature is **moderately known among power users** but rarely used by researchers, who often don't realize they can request parallel exploration of multiple analytical approaches.

### 4. Extended thinking scales reasoning depth on demand

Claude Code supports **extended thinking** — a mechanism that allocates more internal reasoning tokens before Claude acts. This is controlled through specific **trigger keywords** in your prompts that map to different thinking budgets:

| Keyword | Effect |
|---------|--------|
| **"think"** | Standard extended thinking — brief planning |
| **"think harder"** | Deeper analysis, more alternatives considered |
| **"ultrathink"** | Maximum thinking budget — thorough exploration of the solution space |

These words are placed naturally in prompts: *"ultrathink about why this mixed-effects model is producing singular fit warnings"* or *"think harder about the best normalization strategy for this RNA-seq dataset before running PCA."*

Extended thinking is especially valuable for **architecture decisions** (designing a multi-step analysis pipeline), **debugging complex issues** (tracing why a GWAS pipeline produces unexpected QQ plots), and **methodology selection** (choosing between analytical approaches based on data characteristics). The thinking process appears as an internal reasoning block that Claude uses before taking action. **Higher tiers consume more tokens and time but substantially improve quality for genuinely hard problems.** This feature is moderately known — the basic "think" keyword circulates in tips lists, but the escalation tiers ("ultrathink") remain a power-user secret.

### 5. Planning mode separates strategy from execution

**Shift+Tab** in the Claude Code input toggles between normal mode and **plan mode**. In plan mode, Claude analyzes the task and produces a structured plan — listing files to modify, steps to take, and potential risks — without executing anything. You review, modify, or approve the plan before Claude proceeds.

This is transformative for researchers tackling complex, multi-step work. Before writing a single line of code, you can see Claude's full strategy for building a Snakemake pipeline, refactoring an analysis script, or setting up a new statistical workflow. It prevents wasted computation and lets you catch misunderstandings before they become 500-line scripts headed in the wrong direction. **Particularly valuable for HPC work** where a misguided approach wastes expensive cluster time.

### 6. The "interview me" technique gathers requirements before coding

This is a **prompting best practice** rather than a built-in command, but it's one of the most effective patterns for research workflows. Instead of giving Claude Code a complete specification, you ask it to interview you first:

- *"Interview me about my dataset before writing the analysis script"*
- *"Ask me 5-10 questions about my sequencing data, reference genome, and analysis objectives before writing the pipeline"*
- *"Don't start coding yet — ask me one question at a time about my experimental design until you have enough information"*

Claude Code responds with targeted questions about file formats, data dimensions, research hypotheses, preferred statistical methods, output requirements, and edge cases. This surfaces **implicit requirements** researchers often don't think to specify — things like handling missing data, choosing between long vs. wide format, or deciding whether to parallelize across chromosomes. The technique aligns with Anthropic's own best practices for effective prompting. It's **well-known as a concept** but underutilized in practice, especially by researchers who tend to jump straight to "write me a script."

---

## Slide 2: Managing workflows, automation, and context

### 7. CLAUDE.md gives every project persistent memory

CLAUDE.md files act as persistent memory loaded automatically at session start — a project-specific system prompt that survives across sessions. Claude Code supports a **hierarchy** of memory files:

1. **`~/.claude/CLAUDE.md`** — User-level (your personal preferences across all projects)
2. **`./CLAUDE.md`** — Project root (shared with team via git)
3. **`./CLAUDE.local.md`** — Project root, gitignored (personal project preferences)
4. **`./subdirectory/CLAUDE.md`** — Directory-specific context (loaded when working in that directory)

All applicable files are concatenated and included in context. A research-oriented CLAUDE.md might contain:

```markdown
# Project: Population Genomics Pipeline
## Environment
- HPC cluster with SLURM scheduler, partition: --partition=compute
- R 4.3.x with renv, Python 3.11 with conda env `popgen-env`
- Key packages: data.table, vcfR, SNPRelate, ggplot2

## Conventions
- Use data.table (not dplyr) for large genomic datasets
- All scripts include roxygen2 headers and set.seed() calls
- SLURM jobs go in slurm/ with standard headers
- Data >100MB lives in /scratch, symlinked from data/
```

**`/init`** auto-generates a CLAUDE.md by analyzing your project structure. **`/memory`** opens memory files for manual editing. Keep CLAUDE.md **concise and high-signal** — it consumes context window every session. This is a **well-known but often under-optimized feature**; many researchers have a bare-bones version but don't exploit the hierarchy or local overrides.

### 8. Headless mode runs Claude Code inside HPC batch jobs

The **`-p` (print) flag** makes Claude Code non-interactive — it processes a single prompt, outputs results to stdout, and exits. Combined with other flags, this turns Claude Code into a scriptable component for SLURM jobs and CI/CD pipelines.

**Key flags for HPC automation**:

```bash
# Basic headless usage
claude -p "Summarize errors in this alignment log" < bwa_align.err

# Auto-approve all tool use (no interactive prompts)
claude -p --dangerously-skip-permissions "Fix lint errors in scripts/R/"

# Structured JSON output for pipeline parsing
claude -p --output-format json "List all functions in analysis.R"

# Limit agentic turns to prevent runaway
claude -p --max-turns 10 "Refactor the data cleaning module"

# Restrict available tools for safety
claude -p --allowedTools "Read,Grep" "Review this code for bugs"
```

**SLURM integration example**:

```bash
#!/bin/bash
#SBATCH --job-name=code-review
#SBATCH --time=00:30:00
#SBATCH --mem=4G

cd /home/user/my_pipeline
git diff HEAD~5 | claude -p --output-format json \
  "Review these changes for bugs and performance issues" \
  > reviews/review_$(date +%Y%m%d).json
```

Stdin piping works naturally: `cat error.log | claude -p "diagnose this"`. The `--output-format` flag supports `text`, `json`, and `stream-json`. This is a **relatively unknown capability** among researchers — most think of Claude Code as purely interactive. The ability to embed it in batch jobs for automated code review, documentation generation, or log analysis is transformative for HPC workflows.

### 9. Hooks automate actions when Claude edits your code

The **hooks system** runs custom scripts at specific lifecycle events — before or after Claude uses a tool, when it finishes a turn, or when it sends a notification. Configure hooks in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "command": "Rscript -e 'lintr::lint(\"$CLAUDE_FILE_PATH\")'"
      }
    ],
    "Stop": [
      {
        "command": "echo 'Claude finished' | mail -s 'Task done' you@lab.edu"
      }
    ]
  }
}
```

**Hook types**: **PreToolUse** (runs before a tool — can block execution if the script returns non-zero), **PostToolUse** (runs after — ideal for auto-linting or formatting), **Notification**, and **Stop** (when Claude completes a turn). The **`matcher`** field accepts tool name patterns like `"Write"`, `"Bash"`, or `"Edit|Write"`. Environment variables like `$CLAUDE_FILE_PATH` and `$CLAUDE_TOOL_NAME` are available to hook scripts.

**Research use cases**: auto-run `lintr` or `styler` on every R file Claude edits, trigger a SLURM job submission after Claude writes a job script, send Slack notifications when long tasks complete, or log every file modification for reproducibility auditing. This is a **genuinely underused feature** — most users don't know it exists.

### 10. Context management keeps long research sessions productive

Two slash commands prevent context degradation in extended sessions:

**`/compact`** summarizes the current conversation to free context window space while preserving essential information — decisions made, file states, current task progress. It accepts optional focus instructions: `/compact focus on the GWAS pipeline changes`. Claude Code also **auto-compacts** when approaching the context limit. **`/clear`** wipes conversation history entirely for a fresh start (CLAUDE.md is still loaded).

**`/cost`** displays cumulative token usage and estimated cost for the session — critical for researchers on API billing. **Best practice**: compact every 30–60 minutes during heavy sessions, use `/clear` when switching tasks, and store stable context in CLAUDE.md rather than re-explaining each session. Large file reads consume tokens rapidly — let Claude search for specific files rather than reading everything. Understanding context management separates productive power users from those who wonder why Claude "forgot" what they discussed 20 minutes ago.

### 11. GitHub integration handles the full PR lifecycle

Claude Code integrates deeply with GitHub through the **`gh` CLI**. When `gh` is installed and authenticated, Claude can read issues, create branches, make commits with descriptive messages, open pull requests, and respond to review comments — all from natural language instructions.

**Example**: *"Look at issue #42 about the broken phylogenetic tree script, fix it, and submit a PR"* triggers Claude to `gh issue view 42`, read the relevant files, fix the code, create a feature branch, commit, and `gh pr create` with a body that references the issue. The built-in **`/pr-review`** command provides structured code review of pull requests.

For research teams, this means **automated PR descriptions that explain scientific methodology changes**, domain-aware code review (informed by CLAUDE.md project context), and streamlined issue tracking as a lightweight research task manager. This works with GitHub Enterprise as well as standard GitHub.

### 12. Session resume preserves work across SSH disconnections

**`claude --continue`** resumes the most recent conversation; **`claude --resume <session-id>`** resumes a specific past session. Sessions are stored locally in `~/.claude/`. This is essential for HPC researchers who SSH into cluster login nodes — if your connection drops or you need to switch terminals, your entire conversation context is preserved. Combined with `tmux` or `screen`, this creates a resilient workflow where long-running Claude Code sessions survive network interruptions. A small but critical feature that prevents the frustration of re-establishing context after disconnections.

---

## Quick reference for workshop slides

| # | Feature | One-liner | Known? |
|---|---------|-----------|--------|
| 1 | **MCP servers** | Plug Claude into databases, APIs, Slack, GitHub via universal protocol | Known to devs, underused by researchers |
| 2 | **Custom slash commands** | Save lab workflows as reusable `/project:variant-qc` commands | Hidden gem |
| 3 | **Sub-agents** | Claude spawns parallel agents for simultaneous tasks | Moderately known |
| 4 | **Extended thinking** | "think" → "think harder" → "ultrathink" for deeper reasoning | Tiers are a power-user secret |
| 5 | **Planning mode** | Shift+Tab to review strategy before execution | Moderately known |
| 6 | **"Interview me"** | Ask Claude to gather requirements before coding | Known concept, underused |
| 7 | **CLAUDE.md** | Persistent project memory with hierarchical overrides | Known but under-optimized |
| 8 | **Headless mode** | `-p` flag for SLURM batch jobs and CI pipelines | Unknown to most researchers |
| 9 | **Hooks** | Auto-run linting, notifications, logging on Claude's actions | Genuinely underused |
| 10 | **Context management** | `/compact` and `/clear` for long productive sessions | Partially known |
| 11 | **GitHub integration** | Full PR lifecycle from natural language | Well-known |
| 12 | **Session resume** | `--continue` / `--resume` survives SSH drops | Small but critical |