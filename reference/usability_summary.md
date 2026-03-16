# Summarise Usability Evidence

Produces a structured summary of usability evidence, suitable for
printing or for passing to downstream reporting functions.

## Usage

``` r
usability_summary(evidence)
```

## Arguments

- evidence:

  A validated evidence tibble from
  [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
  or any of the individual assessment functions.

## Value

A `usability_result` list (class `"usability_result"`) with:

- study_id:

  The study identifier from the evidence.

- n_vars:

  Number of unique variable locations assessed.

- summary:

  A tibble with per-indicator pass/fail/warn counts and `pct_pass`
  (proportion of passing rows).

- evidence:

  The original evidence tibble.

## Examples

``` r
ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#> ℹ Run context created: "R4S-20260316112448-11kz8bwc"
meta <- data.frame(
  dataset  = c("ADSL", "ADSL"),
  variable = c("USUBJID", "AGE"),
  label    = c("Unique Subject Identifier", "Age"),
  origin   = c("CRF", "Derived"),
  derivation = c(NA, "Derived from BRTHDTC"),
  stringsAsFactors = FALSE
)
ev  <- usability_indicators(meta, ctx = ctx)
#> ✔ Evidence table created: 2 rows
#> ✔ Evidence table created: 2 rows
#> ✔ Evidence table created: 1 row
#> ✔ Evidence table created: 1 row
#> ✔ Bound 4 evidence tables: 6 total rows
res <- usability_summary(ev)
print(res)
#> 
#> ── R4SUB Usability Assessment ──
#> 
#> Study: "STUDY01" | Variables assessed: 4
#> 
#> ✓ Variable Label Quality: 100% pass (2/2)
#> ✓ Define-XML Completeness: 100% pass (2/2)
#> ✓ Annotation Coverage: 100% pass (1/1)
#> ✗ Reviewer Guide Presence: 0% pass (0/1)
#> 
#> ℹ Overall usability score: 75%
```
