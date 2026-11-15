# Check Variable and Dataset Names Against SAS v5 Transport Constraints

Produces a descriptive, tidy report of names that do not conform to the
SAS Version 5 transport (XPT) format naming constraints that still
govern many regulatory submissions. By default a conforming name is at
most eight characters long, is built only from upper-case letters,
digits, and the underscore, and does not start with a digit.

## Usage

``` r
variable_name_conformance(
  names,
  max_length = 8L,
  allowed_chars = "A-Z0-9_",
  allow_leading_digit = FALSE
)
```

## Arguments

- names:

  A character vector of names to check, or a data frame whose column
  names are checked. Anything else is coerced with
  [`as.character()`](https://rdrr.io/r/base/character.html).

- max_length:

  Maximum allowed name length, in characters. Defaults to `8L`, the SAS
  v5 transport limit.

- allowed_chars:

  A regular-expression character-class body describing the permitted
  characters (the text that would appear between `[` and `]`). Defaults
  to `"A-Z0-9_"`: upper-case letters, digits, and the underscore. Use,
  for example, `"A-Za-z0-9_"` to also permit lower-case letters.

- allow_leading_digit:

  Logical; when `FALSE` (the default) a name that begins with a digit is
  reported as `starts_with_digit`.

## Value

A tibble with one row per non-conforming name per reason, and the
columns:

- name:

  The non-conforming name.

- reason:

  One of `"too_long"`, `"invalid_character"`, `"starts_with_digit"`, or
  `"empty"`.

- detail:

  A human-readable description of the finding.

When every name conforms, a zero-row tibble with the same columns is
returned.

## Details

Unlike the scored usability indicators (for example
[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)),
this function does not score anything or emit R4SUB evidence rows; it is
a purely advisory diagnostic. Every reported name may appear on more
than one row when it breaks more than one rule, so the result is tidy
(one row per name per reason). The following reasons are emitted:

- `too_long`:

  The name is longer than `max_length` characters.

- `invalid_character`:

  The name contains at least one character outside the set described by
  `allowed_chars`.

- `starts_with_digit`:

  The first character of the name is a digit. Suppressed when
  `allow_leading_digit = TRUE`.

- `empty`:

  The name is `NA`, empty, or white space only.

The limits are configurable so the same function can check other naming
conventions (for example a longer SAS V8/V9 limit, or a case-insensitive
character set). The defaults encode the documented SAS v5 rule.

## See also

[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)
for the scored U-001 indicator.

## Examples

``` r
# A character vector of variable names
variable_name_conformance(
  c("USUBJID", "SUBJECTID", "trt01p", "2VISIT", "AE_TERM")
)
#> # A tibble: 3 × 3
#>   name      reason            detail                                            
#>   <chr>     <chr>             <chr>                                             
#> 1 2VISIT    starts_with_digit name starts with a digit                          
#> 2 SUBJECTID too_long          name has 9 characters; exceeds maximum of 8       
#> 3 trt01p    invalid_character name contains characters outside the allowed set …

# Check the column names of a data frame directly
df <- data.frame(USUBJID = 1, AgeInYears = 2, check.names = FALSE)
variable_name_conformance(df)
#> # A tibble: 2 × 3
#>   name       reason            detail                                           
#>   <chr>      <chr>             <chr>                                            
#> 1 AgeInYears invalid_character name contains characters outside the allowed set…
#> 2 AgeInYears too_long          name has 10 characters; exceeds maximum of 8     

# Configurable limits: allow lower case and a longer (V8) limit
variable_name_conformance(
  c("trt01p", "SUBJECTIDENTIFIER"),
  max_length = 32L,
  allowed_chars = "A-Za-z0-9_"
)
#> # A tibble: 0 × 3
#> # ℹ 3 variables: name <chr>, reason <chr>, detail <chr>
```
