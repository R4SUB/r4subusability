# Default Usability Assessment Configuration

Returns the default configuration list used by
[`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
and individual assessment functions.

## Usage

``` r
usability_config_default()
```

## Value

A named list with the following elements:

- label_min_chars:

  Minimum recommended label length (integer).

- label_max_chars:

  Maximum recommended label length (integer).

- required_origins:

  Character vector of origins that require a derivation text (e.g.
  `"Derived"`, `"Assigned"`).

- reviewer_guide_keywords:

  Character vector of asset names that count as reviewer guide presence.

- weights:

  Named list of relative indicator weights summing to 1:
  `label_quality`, `define_completeness`, `annotation_coverage`,
  `reviewer_guide`.

## Examples

``` r
cfg <- usability_config_default()
cfg$label_min_chars
#> [1] 3
cfg$weights$label_quality
#> [1] 0.3
```
