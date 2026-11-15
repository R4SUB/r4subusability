# r4subusability

**r4subusability** is the usability pillar package in the R4SUB
ecosystem. It quantifies reviewer-experience indicators for clinical
regulatory submissions, assessing variable label quality, Define-XML
completeness, dataset annotation coverage, and reviewer guide presence.

Evidence rows follow the standard R4SUB schema from `r4subcore`, making
them directly compatible with `r4subscore` (SCI scoring) and
`r4subprofile` (authority-specific profiling).

## Installation

``` r

install.packages("r4subusability")
```

Development version:

``` r

pak::pak(c("R4SUB/r4subcore", "R4SUB/r4subusability"))
```

## Quick Start

``` r

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
|----|----|----|
| [`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md) | U-001 | Variable label length and format |
| [`assess_define_completeness()`](https://r4sub.github.io/r4subusability/reference/assess_define_completeness.md) | U-002 | Define-XML field completeness |
| [`assess_annotation_coverage()`](https://r4sub.github.io/r4subusability/reference/assess_annotation_coverage.md) | U-003 | Dataset annotation coverage |
| [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md) | U-004 | Reviewer guide presence |

## Key Functions

| Function | Purpose |
|----|----|
| [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md) | Default usability thresholds and configuration |
| [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md) | Run all four usability indicators in one call |
| [`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md) | Check variable label quality (U-001) |
| [`assess_define_completeness()`](https://r4sub.github.io/r4subusability/reference/assess_define_completeness.md) | Check Define-XML completeness (U-002) |
| [`assess_annotation_coverage()`](https://r4sub.github.io/r4subusability/reference/assess_annotation_coverage.md) | Check annotation coverage (U-003) |
| [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md) | Check reviewer guide presence (U-004) |
| [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md) | Tidy summary of usability results |
| [`usability_report()`](https://r4sub.github.io/r4subusability/reference/usability_report.md) | Run every scored indicator and advisory diagnostic over one metadata frame and assemble a single consolidated report |

## Consolidated report

[`usability_report()`](https://r4sub.github.io/r4subusability/reference/usability_report.md)
orchestrates the whole package in one call: it runs the four scored
indicators and the advisory diagnostics over a single metadata frame and
assembles a tidy per-check summary, one combined findings frame, and the
R4SUB evidence. It invents no new criteria – the overall score is
exactly the weighted
[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
score over the scored indicators, and the diagnostics contribute
descriptive finding counts only.

``` r

ctx <- r4subcore::r4sub_run_context(study_id = "STUDY-001")
rep <- usability_report(meta, assets = c("ADRG", "define.xml"), ctx = ctx)
rep$checks     # per-check pass/warn/fail/na and finding counts
rep$findings   # combined offending items across all checks
print(rep)
```

## Diagnostics

Alongside the scored indicators, the package provides standalone
diagnostics. These are descriptive aids: they return a tidy tibble of
findings and do **not** emit R4SUB evidence rows or change the
U-001..U-004 indicator scores.

| Function | Purpose |
|----|----|
| [`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md) | Report label-consistency problems in variable metadata: duplicate labels within a dataset, the same variable name carrying inconsistent labels across datasets, and missing dataset-level (table) labels |
| [`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md) | Check variable and dataset names against the SAS v5 transport (XPT) naming constraints: maximum length (eight characters by default), permitted characters (upper-case letters, digits, and underscore), and no leading digit |
| [`variable_attribute_consistency()`](https://r4sub.github.io/r4subusability/reference/variable_attribute_consistency.md) | Report variables whose data attributes (`type`, `length`, `format`) drift across the datasets in which they appear; a variable shared by several datasets is expected to carry the same attributes everywhere |

``` r

meta <- data.frame(
  dataset  = c("ADSL", "ADSL", "ADAE", "ADAE"),
  variable = c("USUBJID", "SUBJID", "USUBJID", "AETERM"),
  label    = c("Subject ID", "Subject ID",
               "Unique Subject Identifier", "Reported Term"),
  stringsAsFactors = FALSE
)
label_consistency(meta)

variable_name_conformance(c("USUBJID", "SUBJECTID", "2VISIT", "AE_TERM"))

attr_meta <- data.frame(
  dataset  = c("ADSL", "ADAE", "ADSL", "ADAE"),
  variable = c("USUBJID", "USUBJID", "AGE", "AGE"),
  type     = c("Char", "Char", "Num", "Char"),
  length   = c(20, 40, 8, 8),
  stringsAsFactors = FALSE
)
variable_attribute_consistency(attr_meta)
```

[`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md)
accepts a character vector or a data frame (whose column names are
checked), and its limits are configurable (`max_length`,
`allowed_chars`, `allow_leading_digit`) for other naming conventions
such as the longer SAS V8/V9 limit.

## Maintained by

R4SUB is part of the open-source work of
[TechWorksLab](https://techworkslab.com) - clinical programming and
regulatory submissions. Maintainer: Pawan Rama Mali.

## License

MIT

## Further reading

- [Define.xml is not documentation. It is the dataset’s
  contract](https://techworkslab.com/insights-define-xml-as-contract),
  the Define-XML completeness this package scores, from TECHWORKSLAB.
