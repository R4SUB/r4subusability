# r4subusability

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/r4subusability)](https://CRAN.R-project.org/package=r4subusability)
<!-- badges: end -->

**r4subusability** is the usability pillar package in the [R4SUB](https://github.com/R4SUB) ecosystem. It quantifies reviewer-experience indicators for clinical regulatory submissions, assessing variable label quality, Define-XML completeness, dataset annotation coverage, and reviewer guide presence.

Evidence rows emitted by r4subusability follow the standard R4SUB schema defined in `r4subcore`, making them directly compatible with `r4subscore` (SCI scoring) and `r4subprofile` (authority-specific profiling).

## Installation

```r
install.packages("r4subusability")
```

## Usage

```r
library(r4subusability)

# Build a minimal metadata data frame
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

## Indicators

| Function | Indicator | Description |
|----------|-----------|-------------|
| `assess_label_quality()` | U-001 | Variable label length and format |
| `assess_define_completeness()` | U-002 | Define-XML field completeness |
| `assess_annotation_coverage()` | U-003 | Dataset annotation coverage |
| `assess_reviewer_guide()` | U-004 | Reviewer guide presence |

## Links

- [Documentation](https://r4sub.github.io/r4subusability/)
- [R4SUB ecosystem](https://r4sub.github.io/r4sub/)
