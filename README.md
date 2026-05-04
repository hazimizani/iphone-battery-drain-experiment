# iPhone Battery Drain — A 2⁴ Factorial Experiment

A designed experiment investigating how four user-controlled iPhone settings affect battery drain over a fixed 15-minute interval. Conducted as a personal applied-statistics project using a full factorial design with blocking, ANOVA, and effect estimation.

## The Experiment

**Response:** Battery percentage drop over a 15-minute window (0.1% precision, read from iOS battery statistics).

**Factors (each at two levels):**

| Factor | Low (-1) | High (+1) |
|---|---|---|
| **A** — Screen Brightness | 25% | 100% |
| **B** — WiFi | Off (Airplane mode) | On (connected) |
| **C** — App Workload | Idle (home screen) | Active (local video loop) |
| **D** — Low Power Mode | On | Off |

**Design:** 2⁴ full factorial → 16 treatment combinations × 3 replicates = **48 runs**, with one full replicate per day (Day used as a blocking factor). Run order randomized within each block.

## What's in the Repo

```
.
├── report.Rmd / report.pdf   Analysis and write-up
├── data/
│   ├── battery_drain.csv     Run-level data (48 rows)
│   └── README.md             Data dictionary
└── R/
    ├── helpers.R             Reusable analysis functions
    │                          (half-normal plot, effect calc,
    │                          interaction panel, diagnostics,
    │                          Lenth's test)
    └── simulate_data.R       Reproducible data simulator
                               (set.seed used)
```

## Reproducing the Analysis

Requires R with `rmarkdown` and a LaTeX install (e.g. TinyTeX). From the repo root:

```bash
# Render the report (uses data/battery_drain.csv)
Rscript -e "rmarkdown::render('report.Rmd')"

# Or regenerate the simulated dataset first
Rscript R/simulate_data.R
```

## Methods

The analysis uses base R only (no tidyverse):

- ANOVA via `aov()` and `lm()` on the full 2⁴ model with Day as a block
- Effect estimates from regression coefficients (×2 convention)
- **Half-normal plot** to identify active effects
- **Lenth's pseudo-standard-error test** for unreplicated effect screening
- Interaction plots for significant two-factor interactions
- Standard residual diagnostics (normality, equal variance, independence)

## Notes

This is a personal project. Data was collected on a single iPhone over three days under reasonably controlled conditions; results are illustrative of the methodology, not a manufacturer-grade benchmark.
