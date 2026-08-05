# Assess All Usability Indicators

Convenience wrapper that runs all four usability assessments and returns
a combined evidence table. This is the primary entry point for the
`r4subusability` package.

## Usage

``` r
usability_indicators(metadata, assets = character(0), ctx, config = NULL)
```

## Arguments

- metadata:

  A data frame with columns `dataset`, `variable`, `label`, `origin`,
  `derivation` (optional), and `codelist` (optional). Compatible with
  the `adam_metadata` and `sdtm_metadata` datasets from `r4subdata`.

- assets:

  A character vector of asset names present in the submission package.
  Used by
  [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md).
  Defaults to `character(0)`.

- ctx:

  A run context created by
  [`r4subcore::r4sub_run_context()`](https://rdrr.io/pkg/r4subcore/man/r4sub_run_context.html).

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md).
  If `NULL` the default configuration is used.

## Value

A validated evidence tibble combining results from all four usability
assessments (see
[`r4subcore::as_evidence()`](https://rdrr.io/pkg/r4subcore/man/as_evidence.html)).

## Examples

``` r
ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
ev  <- suppressMessages(usability_indicators(
  r4subdata::oncology_metadata,
  assets = c("ADRG", "define.xml"),
  ctx = ctx
))
#> Error: 'oncology_metadata' is not an exported object from 'namespace:r4subdata'
table(ev$indicator_id, ev$result)
#> Error: object 'ev' not found
```
