# Changelog

## r4subusability (development version)

- Add
  [`usability_report()`](https://r4sub.github.io/r4subusability/reference/usability_report.md):
  a consolidated rollup that runs every usability check in the package
  over one metadata frame in a single call and assembles the results
  into one `usability_report` object. It orchestrates the scored
  indicators
  ([`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md),
  U-001..U-004) and the advisory diagnostics
  ([`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md),
  [`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md),
  [`variable_attribute_consistency()`](https://r4sub.github.io/r4subusability/reference/variable_attribute_consistency.md)),
  returning a tidy per-check summary (pass/warn/fail/na counts and
  finding counts), a single combined findings frame of the offending
  items, and the combined R4SUB evidence. It invents no new criteria:
  the overall score is exactly the weighted score from
  [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
  over the scored indicators, and the diagnostics contribute descriptive
  finding counts only. A [`print()`](https://rdrr.io/r/base/print.html)
  method is included.
- Add
  [`variable_attribute_consistency()`](https://r4sub.github.io/r4subusability/reference/variable_attribute_consistency.md):
  a descriptive diagnostic that reports variables whose data attributes
  (`type`, `length`, `format`) drift across the datasets in which they
  appear. A variable name shared by several datasets is expected to
  carry the same type, length, and format everywhere; mismatches are
  reported as a tidy tibble, one row per affected dataset per attribute.
  The attributes checked are configurable and absent columns are
  skipped. It is purely additive and does not affect existing usability
  scores.
- Add
  [`variable_name_conformance()`](https://r4sub.github.io/r4subusability/reference/variable_name_conformance.md):
  a descriptive diagnostic that checks variable and dataset names
  against the SAS v5 transport (XPT) naming constraints (maximum length
  of eight characters; upper-case letters, digits, and underscore only;
  not starting with a digit). The limits are configurable and the result
  is a tidy tibble of non-conforming names with the reason. It is purely
  additive and does not affect existing usability scores.
- Add
  [`label_consistency()`](https://r4sub.github.io/r4subusability/reference/label_consistency.md):
  a descriptive diagnostic that reports duplicate labels within a
  dataset, the same variable name carrying inconsistent labels across
  datasets, and missing dataset-level (table) labels, as a tidy tibble.
  It is purely additive and does not affect existing usability scores.
- Fix the README quick-start example, which called
  [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
  with a non-existent `study_id` argument and omitted the required run
  context.
- Correct the usability-indicators vignette: drop the stale `"ARG"`
  entry from the documented `reviewer_guide_keywords` defaults, and
  describe the reviewer guide match as word-boundary (not substring)
  matching, to match the code.

## r4subusability 0.2.1

- Fix the pkgdown workflow so it resolves ecosystem dependencies, and
  polish metadata for CRAN.

## r4subusability 0.2.0

- Add vignette: “Case study: reviewer experience from ADaM metadata”,
  which builds a Define-style view from the example CDISC pilot metadata
  in `r4subdata` and measures its usability.

- Clarified the package DESCRIPTION: “R4SUB” expands to “Ready for
  Submission” (previously “R for Regulatory Submission”, inconsistent
  with the rest of the ecosystem).

## r4subusability 0.1.0

- Initial release.
- [`usability_config_default()`](https://r4sub.github.io/r4subusability/reference/usability_config_default.md):
  default configuration for usability assessments.
- [`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md):
  check variable label presence and length (U-001).
- [`assess_define_completeness()`](https://r4sub.github.io/r4subusability/reference/assess_define_completeness.md):
  check Define-XML origin and derivation fields (U-002).
- [`assess_annotation_coverage()`](https://r4sub.github.io/r4subusability/reference/assess_annotation_coverage.md):
  check proportion of derived variables annotated (U-003).
- [`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md):
  check reviewer guide presence in submission package (U-004).
- [`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md):
  run all four assessments in one call.
- [`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
  and
  [`print.usability_result()`](https://r4sub.github.io/r4subusability/reference/print.usability_result.md):
  summarise and display results.
