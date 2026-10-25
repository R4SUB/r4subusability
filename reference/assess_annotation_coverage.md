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
  [`r4subcore::r4sub_run_context()`](https://r4sub.github.io/r4subcore/reference/r4sub_run_context.html).

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md).
  If `NULL` the default configuration is used.

## Value

A validated evidence tibble (see
[`r4subcore::as_evidence()`](https://r4sub.github.io/r4subcore/reference/as_evidence.html)).

## Examples

``` r
ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
ev  <- suppressMessages(
  assess_annotation_coverage(r4subdata::oncology_metadata, ctx)
)
ev[, c("asset_id", "result", "metric_value")]
#>   asset_id result metric_value
#> 1     ADSL   fail          0.5
#> 2     ADRS   pass          1.0
#> 3    ADTTE   pass          1.0
```
