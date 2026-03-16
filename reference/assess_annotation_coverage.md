# Assess Dataset Annotation Coverage

Checks what proportion of derived variables have derivation text
documented. Returns one evidence row per dataset summarising annotation
coverage, with `indicator_id = "U-003"`.

## Usage

``` r
assess_annotation_coverage(metadata, ctx, config = NULL)
```

## Arguments

- metadata:

  A data frame with columns `dataset`, `variable`, `origin`, and
  `derivation`.

- ctx:

  A run context created by
  [`r4subcore::r4sub_run_context()`](https://rdrr.io/pkg/r4subcore/man/r4sub_run_context.html).

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md).
  If `NULL` the default configuration is used.

## Value

A validated evidence tibble (see
[`r4subcore::as_evidence()`](https://rdrr.io/pkg/r4subcore/man/as_evidence.html)).

## Examples

``` r
ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#> ℹ Run context created: "R4S-20260316111249-wl4dieex"
meta <- data.frame(
  dataset    = c("ADSL", "ADSL", "ADSL"),
  variable   = c("AGE", "SEX", "RACE"),
  origin     = c("Derived", "CRF", "Derived"),
  derivation = c("Derived from BRTHDTC", NA, NA),
  stringsAsFactors = FALSE
)
ev <- assess_annotation_coverage(meta, ctx)
#> ✔ Evidence table created: 1 row
ev$metric_value
#> [1] 0.5
```
