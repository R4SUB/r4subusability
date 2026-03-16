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
# \donttest{
ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#> ℹ Run context created: "R4S-20260316173058-f7ayh65s"
meta <- data.frame(
  dataset    = c("ADSL", "ADSL", "ADAE"),
  variable   = c("USUBJID", "AGE", "AETERM"),
  label      = c("Unique Subject Identifier", "Age", "Adverse Event Term"),
  origin     = c("CRF", "Derived", "CRF"),
  derivation = c(NA, "Derived from BRTHDTC and RFSTDTC", NA),
  stringsAsFactors = FALSE
)
assets <- c("ADRG", "define.xml")
ev <- usability_indicators(meta, assets = assets, ctx = ctx)
#> ✔ Evidence table created: 3 rows
#> ✔ Evidence table created: 3 rows
#> ✔ Evidence table created: 2 rows
#> ✔ Evidence table created: 1 row
#> ✔ Bound 4 evidence tables: 9 total rows
nrow(ev)
#> [1] 9
table(ev$result)
#> 
#>   na pass 
#>    1    8 
# }
```
