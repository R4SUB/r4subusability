# Print a Consolidated Usability Report

Print a Consolidated Usability Report

## Usage

``` r
# S3 method for class 'usability_report'
print(x, ...)
```

## Arguments

- x:

  A `usability_report` object returned by
  [`usability_report()`](https://r4sub.github.io/r4subusability/reference/usability_report.md).

- ...:

  Ignored.

## Value

Invisibly returns `x`. Called for its side effect of printing the
scored-indicator pass rates, the weighted overall score, and the
advisory diagnostic finding counts to the console.
