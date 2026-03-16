# r4subusability

<!-- badges: start -->
[![R-CMD-check](https://github.com/R4SUB/r4subusability/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/R4SUB/r4subusability/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/r4subusability)](https://CRAN.R-project.org/package=r4subusability)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/r4subusability)](https://CRAN.R-project.org/package=r4subusability)
[![r-universe](https://r4sub.r-universe.dev/badges/r4subusability)](https://r4sub.r-universe.dev/r4subusability)
<!-- badges: end -->

**r4subusability** is the usability pillar package in the R4SUB ecosystem. It quantifies reviewer-experience indicators for clinical regulatory submissions, assessing variable label quality, Define-XML completeness, dataset annotation coverage, and reviewer guide presence.

Evidence rows follow the standard R4SUB schema from `r4subcore`, making them directly compatible with `r4subscore` (SCI scoring) and `r4subprofile` (authority-specific profiling).

## Installation

```r
install.packages("r4subusability")
```

Development version:

```r
pak::pak(c("R4SUB/r4subcore", "R4SUB/r4subusability"))
```

## Quick Start

```r
library(r4subusability)

meta <- data.frame(
  dataset  = c("ADSL", "ADAE"),
  variable = c("USUBJID", "AETERM"),
  label    = c("Unique Subject Identifier", "Reported Term for the Adverse Event"),
  origin   = c("Assigned", "CRF"),
  type     = c("text", "text"),
  stringsAsFactors = FALSE
)

results <- usability_indicators(meta, study_id = "STUDY-001")
usability_summary(results)
```

## Usability Indicators

| Function | Indicator | Description |
|---|---|---|
| `assess_label_quality()` | U-001 | Variable label length and format |
| `assess_define_completeness()` | U-002 | Define-XML field completeness |
| `assess_annotation_coverage()` | U-003 | Dataset annotation coverage |
| `assess_reviewer_guide()` | U-004 | Reviewer guide presence |

## Key Functions

| Function | Purpose |
|---|---|
| `usability_config_default()` | Default usability thresholds and configuration |
| `usability_indicators()` | Run all four usability indicators in one call |
| `assess_label_quality()` | Check variable label quality (U-001) |
| `assess_define_completeness()` | Check Define-XML completeness (U-002) |
| `assess_annotation_coverage()` | Check annotation coverage (U-003) |
| `assess_reviewer_guide()` | Check reviewer guide presence (U-004) |
| `usability_summary()` | Tidy summary of usability results |

## License

MIT
