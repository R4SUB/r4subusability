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
ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
ev  <- suppressMessages(
  assess_annotation_coverage(r4subdata::oncology_metadata, ctx)
)
#> Error: 'oncology_metadata' is not an exported object from 'namespace:r4subdata'
ev[, c("asset_id", "result", "metric_value")]
#> Error: object 'ev' not found
```
