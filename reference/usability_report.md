# Consolidated Usability Report

Runs every usability check the package provides over one metadata frame
in a single call and assembles the results into one coherent report. It
is a pure orchestration and aggregation layer: it invents **no** new
pass/warn/fail criteria, thresholds, or scores. The scored indicators
keep their own U-001..U-004 semantics and weighted roll-up (from
[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)),
and the advisory diagnostics keep their descriptive, unscored finding
counts.

## Usage

``` r
usability_report(
  metadata,
  assets = character(0),
  ctx,
  config = NULL,
  diagnostics = TRUE
)
```

## Arguments

- metadata:

  A data frame with columns `dataset`, `variable`, `label`, `origin`,
  `derivation` (optional), and `codelist` (optional). May span several
  datasets (one row per variable per dataset). Compatible with the
  `adam_metadata`, `sdtm_metadata`, and `oncology_metadata` datasets
  from `r4subdata`.

- assets:

  A character vector of asset names present in the submission package,
  passed to
  [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md).
  Defaults to `character(0)`.

- ctx:

  A run context created by
  [`r4subcore::r4sub_run_context()`](https://r4sub.github.io/r4subcore/reference/r4sub_run_context.html).

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md).
  If `NULL` the default configuration is used.

- diagnostics:

  Logical; when `TRUE` (the default) the advisory diagnostics are run
  and aggregated alongside the scored indicators. When `FALSE` only the
  scored indicators are reported.

## Value

A `usability_report` object (a list with class `"usability_report"`)
with:

- study_id:

  The study identifier from the evidence.

- n_datasets:

  Number of distinct datasets in `metadata`.

- n_vars:

  Number of variable-level locations assessed (as counted by
  [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)).

- overall_score:

  The weighted scored-indicator score from
  [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md);
  `NA` when nothing is applicable.

- n_fail,n_warn:

  Total `fail` and `warn` rows across the scored indicators.

- n_findings:

  Total number of advisory diagnostic findings.

- checks:

  A tidy per-check summary tibble: one row per check with `check`,
  `check_name`, `check_type` (`"scored"` or `"diagnostic"`), `n_items`,
  `n_pass`, `n_warn`, `n_fail`, `n_na`, `n_findings`, and `pct_pass`.
  Scored-only columns are `NA` for diagnostics.

- findings:

  A combined tidy tibble of the offending items across all checks, with
  columns `check`, `check_type`, `finding_type`, `dataset`, `variable`,
  and `detail`.

- evidence:

  The combined R4SUB evidence tibble from the scored indicators (see
  [`r4subcore::as_evidence()`](https://r4sub.github.io/r4subcore/reference/as_evidence.html)).

- scored:

  The
  [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
  result for the scored indicators.

- config:

  The configuration used.

## Details

Two families of check are combined:

- Scored indicators:

  [`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)
  (U-001),
  [`assess_define_completeness()`](https://r4sub.github.io/r4subusability/reference/assess_define_completeness.md)
  (U-002),
  [`assess_annotation_coverage()`](https://r4sub.github.io/r4subusability/reference/assess_annotation_coverage.md)
  (U-003), and
  [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md)
  (U-004), run together through
  [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md).
  These emit validated R4SUB evidence and carry pass/warn/fail/na
  results and a weighted overall score.

- Advisory diagnostics:

  [`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md),
  [`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md)
  (run over the distinct variable names), and
  [`variable_attribute_consistency()`](https://r4sub.github.io/r4subusability/reference/variable_attribute_consistency.md).
  These are descriptive: they report a tidy set of findings and are
  never scored or rolled into the overall score.

The overall usability score is exactly the weighted score from
[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
over the four scored indicators; the diagnostics contribute only finding
counts, never a pass/fail judgement.

## See also

[`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
and
[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
for the scored indicators;
[`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md),
[`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md),
and
[`variable_attribute_consistency()`](https://r4sub.github.io/r4subusability/reference/variable_attribute_consistency.md)
for the advisory diagnostics.

## Examples

``` r
ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
rep <- suppressMessages(usability_report(
  r4subdata::oncology_metadata,
  assets = c("ADRG", "define.xml"),
  ctx = ctx
))
rep$checks
#> # A tibble: 7 × 10
#>   check      check_name check_type n_items n_pass n_warn n_fail  n_na n_findings
#>   <chr>      <chr>      <chr>        <int>  <int>  <int>  <int> <int>      <int>
#> 1 U-001      Variable … scored          32     32      0      0     0          0
#> 2 U-002      Define-XM… scored          32     29      0      3     0          3
#> 3 U-003      Annotatio… scored           3      2      0      1     0          1
#> 4 U-004      Reviewer … scored           1      1      0      0     0          0
#> 5 label_con… Label Con… diagnostic      NA     NA     NA     NA    NA          0
#> 6 variable_… Variable … diagnostic      NA     NA     NA     NA    NA          0
#> 7 variable_… Variable … diagnostic      NA     NA     NA     NA    NA          0
#> # ℹ 1 more variable: pct_pass <dbl>
print(rep)
#> 
#> ── R4SUB Usability Report ──
#> 
#> Study: "STUDY01" | Datasets: 3 | Variables assessed: 32
#> 
#> Scored indicators
#> ✓ Variable Label Quality: 100% pass (32/32)
#> ✓ Define-XML Completeness: 90.6% pass (29/32)
#> ✗ Annotation Coverage: 66.7% pass (2/3)
#> ✓ Reviewer Guide Presence: 100% pass (1/1)
#> 
#> Advisory diagnostics (descriptive, unscored)
#> ✓ Label Consistency: no findings
#> ✓ Variable Name Conformance: no findings
#> ✓ Variable Attribute Consistency: no findings
#> 
#> ℹ Overall usability score: 88.4%
```
