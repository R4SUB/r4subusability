# Assess Reviewer Guide Presence

Checks whether a reviewer guide document (Analysis Data Reviewer's Guide
or Study Data Reviewer's Guide) is declared in the submission asset
list. Returns evidence rows with `indicator_id = "U-004"`.

## Usage

``` r
assess_reviewer_guide(assets, ctx, config = NULL)
```

## Arguments

- assets:

  A character vector of asset names or file names present in the
  submission package (e.g. `c("ADRG", "define.xml", "datasets")`).

- ctx:

  A run context created by
  [`r4subcore::r4sub_run_context()`](https://rdrr.io/pkg/r4subcore/man/r4sub_run_context.html).

- config:

  A configuration list from
  [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md).
  If `NULL` the default configuration is used.

## Value

A validated evidence tibble with one row (see
[`r4subcore::as_evidence()`](https://rdrr.io/pkg/r4subcore/man/as_evidence.html)).

## Examples

``` r
ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#> ℹ Run context created: "R4S-20260316101228-vj57qv4a"
ev_present <- assess_reviewer_guide(c("ADRG", "define.xml"), ctx)
#> ✔ Evidence table created: 1 row
ev_missing <- assess_reviewer_guide(c("define.xml"), ctx)
#> ✔ Evidence table created: 1 row
ev_present$result
#> [1] "pass"
ev_missing$result
#> [1] "fail"
```
