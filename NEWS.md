# r4subusability (development version)

- Add `variable_name_conformance()`: a descriptive diagnostic that checks
  variable and dataset names against the SAS v5 transport (XPT) naming
  constraints (maximum length of eight characters; upper-case letters, digits,
  and underscore only; not starting with a digit). The limits are configurable
  and the result is a tidy tibble of non-conforming names with the reason. It
  is purely additive and does not affect existing usability scores.
- Add `label_consistency()`: a descriptive diagnostic that reports duplicate
  labels within a dataset, the same variable name carrying inconsistent labels
  across datasets, and missing dataset-level (table) labels, as a tidy tibble.
  It is purely additive and does not affect existing usability scores.
- Fix the README quick-start example, which called `usability_indicators()`
  with a non-existent `study_id` argument and omitted the required run context.
- Correct the usability-indicators vignette: drop the stale `"ARG"` entry from
  the documented `reviewer_guide_keywords` defaults, and describe the reviewer
  guide match as word-boundary (not substring) matching, to match the code.

# r4subusability 0.2.1

- Fix the pkgdown workflow so it resolves ecosystem dependencies, and polish metadata for CRAN.

# r4subusability 0.2.0

- Add vignette: "Case study: reviewer experience from ADaM metadata", which
  builds a Define-style view from the example CDISC pilot metadata in
  `r4subdata` and measures its usability.

- Clarified the package DESCRIPTION: "R4SUB" expands to "Ready for Submission"
  (previously "R for Regulatory Submission", inconsistent with the rest of the
  ecosystem).

# r4subusability 0.1.0

- Initial release.
- `usability_config_default()`: default configuration for usability assessments.
- `assess_label_quality()`: check variable label presence and length (U-001).
- `assess_define_completeness()`: check Define-XML origin and derivation fields (U-002).
- `assess_annotation_coverage()`: check proportion of derived variables annotated (U-003).
- `assess_reviewer_guide()`: check reviewer guide presence in submission package (U-004).
- `usability_indicators()`: run all four assessments in one call.
- `usability_summary()` and `print.usability_result()`: summarise and display results.
