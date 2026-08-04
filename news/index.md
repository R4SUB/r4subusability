# Changelog

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
