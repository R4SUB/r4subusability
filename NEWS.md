# r4subusability (development version)

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
