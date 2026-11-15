# Diagnose Cross-Dataset Variable Attribute Consistency

Produces a descriptive, tidy report of variables whose data
**attributes** drift across the datasets in which they appear. A
variable name that is used in more than one dataset (for example
`USUBJID` in `ADSL` and `ADAE`) is expected to carry the same data type,
storage length, and display format everywhere; a mismatch is a common,
objective source of reviewer friction and a frequent cause of
transport-file surprises.

## Usage

``` r
variable_attribute_consistency(
  metadata,
  attributes = c("type", "length", "format")
)
```

## Arguments

- metadata:

  A data frame with at least columns `dataset` (character) and
  `variable` (character), plus any of the attribute columns named in
  `attributes`. Compatible with the `adam_metadata`, `sdtm_metadata`,
  and `oncology_metadata` datasets from `r4subdata`.

- attributes:

  A character vector naming the attribute columns to check for
  cross-dataset consistency. Defaults to
  `c("type", "length", "format")`. Any name not present in `metadata` is
  skipped.

## Value

A tibble with one row per finding and the columns:

- finding_type:

  One of `"inconsistent_type"`, `"inconsistent_length"`, or
  `"inconsistent_format"` (one per checked attribute).

- variable:

  The variable whose attribute is inconsistent.

- dataset:

  The dataset this row reports.

- attribute:

  The name of the attribute column involved.

- value:

  The attribute value this variable carries in this dataset (as
  character).

- detail:

  A human-readable description of the finding.

When every shared variable is consistent, a zero-row tibble with the
same columns is returned.

## Details

Like
[`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md)
and
[`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md),
and unlike the scored usability indicators (for example
[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)),
this function does not score anything or emit R4SUB evidence rows; it is
a purely advisory diagnostic. The result is tidy: one row per affected
dataset occurrence per attribute, so a variable that differs on both
type and length appears under two finding types. The following finding
types may be emitted, one per checked attribute column that is present
in `metadata`:

- `inconsistent_type`:

  The `type` attribute differs across datasets.

- `inconsistent_length`:

  The `length` attribute differs across datasets.

- `inconsistent_format`:

  The `format` attribute differs across datasets.

Only the attribute columns named in `attributes` that are actually
present in `metadata` are checked; requested attributes that are absent
are silently skipped, so the function is safe to call on metadata that
carries only some of them. Values are compared after trimming leading
and trailing white space; `NA` and empty-string values are treated as
missing and never drive a finding, so a variable that simply lacks (say)
a format in one dataset is not reported.

## See also

[`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md)
for label-level consistency and
[`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md)
for name conformance.

## Examples

``` r
meta <- data.frame(
  dataset  = c("ADSL", "ADAE", "ADSL", "ADAE"),
  variable = c("USUBJID", "USUBJID", "AGE", "AGE"),
  type     = c("Char", "Char", "Num", "Char"),
  length   = c(20, 40, 8, 8),
  stringsAsFactors = FALSE
)
# USUBJID differs in length; AGE differs in type.
variable_attribute_consistency(meta)
#> # A tibble: 4 × 6
#>   finding_type        variable dataset attribute value detail                   
#>   <chr>               <chr>    <chr>   <chr>     <chr> <chr>                    
#> 1 inconsistent_length USUBJID  ADAE    length    40    variable 'USUBJID' has 2…
#> 2 inconsistent_length USUBJID  ADSL    length    20    variable 'USUBJID' has 2…
#> 3 inconsistent_type   AGE      ADAE    type      Char  variable 'AGE' has 2 dis…
#> 4 inconsistent_type   AGE      ADSL    type      Num   variable 'AGE' has 2 dis…

# Restrict the check to a single attribute.
variable_attribute_consistency(meta, attributes = "type")
#> # A tibble: 2 × 6
#>   finding_type      variable dataset attribute value detail                     
#>   <chr>             <chr>    <chr>   <chr>     <chr> <chr>                      
#> 1 inconsistent_type AGE      ADAE    type      Char  variable 'AGE' has 2 disti…
#> 2 inconsistent_type AGE      ADSL    type      Num   variable 'AGE' has 2 disti…
```
