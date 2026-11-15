# Diagnose Variable Label Consistency

Produces a descriptive, tidy report of label-consistency problems in
variable metadata. Unlike
[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)
(indicator U-001), this function does not score or emit R4SUB evidence
rows; it is a diagnostic aid that surfaces three classes of finding:

## Usage

``` r
label_consistency(metadata)
```

## Arguments

- metadata:

  A data frame with at least columns `dataset` (character), `variable`
  (character), and `label` (character). An optional `table_label` column
  (character) supplies the dataset-level label used for the
  `missing_table_label` check.

## Value

A tibble with one row per finding and the columns:

- finding_type:

  One of `"duplicate_label"`, `"inconsistent_label"`, or
  `"missing_table_label"`.

- dataset:

  The dataset the finding relates to.

- variable:

  The variable the finding relates to, or `NA` for a dataset-level
  finding.

- label:

  The variable label involved, or `NA` where not applicable.

- detail:

  A human-readable description of the finding.

When there are no findings, a zero-row tibble with the same columns is
returned.

## Details

- `duplicate_label`:

  Two or more variables in the *same* dataset share an identical
  (non-empty) label.

- `inconsistent_label`:

  A variable name that appears in more than one dataset carries
  different labels across those datasets.

- `missing_table_label`:

  A dataset has no dataset-level (table) label. Only checked when a
  `table_label` column is supplied.

Comparisons ignore leading and trailing white space. Empty strings and
`NA` are treated as missing labels and never counted as duplicates or
inconsistencies.

## See also

[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)
for the scored U-001 indicator.

## Examples

``` r
meta <- data.frame(
  dataset  = c("ADSL", "ADSL", "ADAE", "ADAE"),
  variable = c("USUBJID", "SUBJID", "USUBJID", "AETERM"),
  label    = c("Subject ID", "Subject ID",
               "Unique Subject Identifier", "Reported Term"),
  stringsAsFactors = FALSE
)
label_consistency(meta)
#> # A tibble: 4 × 5
#>   finding_type       dataset variable label                     detail          
#>   <chr>              <chr>   <chr>    <chr>                     <chr>           
#> 1 duplicate_label    ADSL    SUBJID   Subject ID                label 'Subject …
#> 2 duplicate_label    ADSL    USUBJID  Subject ID                label 'Subject …
#> 3 inconsistent_label ADAE    USUBJID  Unique Subject Identifier variable 'USUBJ…
#> 4 inconsistent_label ADSL    USUBJID  Subject ID                variable 'USUBJ…

# With a dataset-level (table) label column
meta2 <- data.frame(
  dataset     = c("ADSL", "ADAE"),
  variable    = c("USUBJID", "USUBJID"),
  label       = c("Unique Subject Identifier", "Unique Subject Identifier"),
  table_label = c("Subject-Level Analysis Dataset", ""),
  stringsAsFactors = FALSE
)
label_consistency(meta2)
#> # A tibble: 1 × 5
#>   finding_type        dataset variable label detail                             
#>   <chr>               <chr>   <chr>    <chr> <chr>                              
#> 1 missing_table_label ADAE    NA       NA    dataset 'ADAE' has no dataset-leve…
```
