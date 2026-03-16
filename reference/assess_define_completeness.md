# Assess Define-XML Completeness

Evaluates whether all datasets and variables in the metadata have the
required Define-XML fields populated (label, origin, derivation for
derived variables, and codelist reference where applicable). Results are
returned as R4SUB evidence rows with `indicator_id = "U-002"`.

## Usage

``` r
assess_define_completeness(metadata, ctx, config = NULL)
```

## Arguments

- metadata:

  A data frame with columns `dataset`, `variable`, `label`, `origin`
  (character), `derivation` (character, may be `NA`), and `codelist`
  (character, may be `NA`).

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
#> ℹ Run context created: "R4S-20260316112447-ombeu7fd"
meta <- data.frame(
  dataset    = c("ADSL", "ADSL"),
  variable   = c("USUBJID", "AGE"),
  label      = c("Unique Subject Identifier", "Age"),
  origin     = c("CRF", "Derived"),
  derivation = c(NA, "Derived from BRTHDTC"),
  codelist   = c(NA, NA),
  stringsAsFactors = FALSE
)
ev <- assess_define_completeness(meta, ctx)
#> ✔ Evidence table created: 2 rows
nrow(ev)
#> [1] 2
```
