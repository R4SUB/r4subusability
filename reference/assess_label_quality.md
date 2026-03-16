# Assess Variable Label Quality

Evaluates the quality of variable labels in a metadata data frame. Each
variable is checked for label presence, length within the recommended
range, and absence of prohibited characters. Results are returned as
R4SUB evidence rows with `indicator_id = "U-001"`.

## Usage

``` r
assess_label_quality(metadata, ctx, config = NULL)
```

## Arguments

- metadata:

  A data frame with at least columns `dataset` (character), `variable`
  (character), and `label` (character).

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
#> ℹ Run context created: "R4S-20260316173057-78yvg5fi"
meta <- data.frame(
  dataset  = c("ADSL", "ADSL", "ADAE"),
  variable = c("USUBJID", "AGE", "AETERM"),
  label    = c("Unique Subject Identifier", "Age", ""),
  stringsAsFactors = FALSE
)
ev <- assess_label_quality(meta, ctx)
#> ✔ Evidence table created: 3 rows
nrow(ev)
#> [1] 3
```
