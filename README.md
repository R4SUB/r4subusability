# r4subusability

<!-- badges: start -->
[![R-CMD-check](https://github.com/R4SUB/r4subusability/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/R4SUB/r4subusability/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/r4subusability)](https://CRAN.R-project.org/package=r4subusability)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/r4subusability)](https://CRAN.R-project.org/package=r4subusability)
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
  stringsAsFactors = FALSE
)

ctx     <- r4subcore::r4sub_run_context(study_id = "STUDY-001")
results <- usability_indicators(meta, assets = c("ADRG", "define.xml"), ctx = ctx)
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

## Diagnostics

Alongside the scored indicators, the package provides standalone diagnostics. These are descriptive aids: they return a tidy tibble of findings and do **not** emit R4SUB evidence rows or change the U-001..U-004 indicator scores.

| Function | Purpose |
|---|---|
| `label_consistency()` | Report label-consistency problems in variable metadata: duplicate labels within a dataset, the same variable name carrying inconsistent labels across datasets, and missing dataset-level (table) labels |
| `variable_name_conformance()` | Check variable and dataset names against the SAS v5 transport (XPT) naming constraints: maximum length (eight characters by default), permitted characters (upper-case letters, digits, and underscore), and no leading digit |

```r
meta <- data.frame(
  dataset  = c("ADSL", "ADSL", "ADAE", "ADAE"),
  variable = c("USUBJID", "SUBJID", "USUBJID", "AETERM"),
  label    = c("Subject ID", "Subject ID",
               "Unique Subject Identifier", "Reported Term"),
  stringsAsFactors = FALSE
)
label_consistency(meta)

variable_name_conformance(c("USUBJID", "SUBJECTID", "2VISIT", "AE_TERM"))
```

`variable_name_conformance()` accepts a character vector or a data frame (whose column names are checked), and its limits are configurable (`max_length`, `allowed_chars`, `allow_leading_digit`) for other naming conventions such as the longer SAS V8/V9 limit.

## Maintained by

R4SUB is part of the open-source work of [TechWorksLab](https://techworkslab.com) - clinical programming and regulatory submissions. Maintainer: Pawan Rama Mali.

## License

MIT

## Further reading

- [Define.xml is not documentation. It is the dataset's contract](https://techworkslab.com/insights-define-xml-as-contract), the Define-XML completeness this package scores, from TECHWORKSLAB.
