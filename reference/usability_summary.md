# Summarise Usability Evidence

Produces a structured summary of usability evidence, suitable for
printing or for passing to downstream reporting functions.

## Usage

``` r
usability_summary(evidence, config = NULL)
```

## Arguments

- evidence:

  A validated evidence tibble from
  [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
  or any of the individual assessment functions.

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md),
  used for the per-indicator weights in the overall score. If `NULL` the
  default configuration is used.

## Value

A `usability_result` list (class `"usability_result"`) with:

- study_id:

  The study identifier from the evidence.

- n_vars:

  Number of unique variable-level locations assessed (the label and
  Define completeness checks).

- overall_score:

  The weighted mean of the per-indicator pass proportions, using the
  configuration weights; `NA` if nothing is applicable.

- summary:

  A tibble with per-indicator pass/fail/warn/na counts and `pct_pass`
  (passing rows over applicable rows, excluding `"na"`).

- evidence:

  The original evidence tibble.

## Examples

``` r
ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
ev  <- suppressMessages(
  usability_indicators(r4subdata::oncology_metadata, ctx = ctx)
)
res <- usability_summary(ev)
print(res)
#> 
#> ── R4SUB Usability Assessment ──
#> 
#> Study: "STUDY01" | Variables assessed: 32
#> 
#> ✓ Variable Label Quality: 100% pass (32/32)
#> ✓ Define-XML Completeness: 90.6% pass (29/32)
#> ✗ Annotation Coverage: 66.7% pass (2/3)
#> ✗ Reviewer Guide Presence: 0% pass (0/1)
#> 
#> ℹ Overall usability score: 78.4%
```
