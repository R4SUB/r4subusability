# Usability Indicators with r4subusability

``` r
library(r4subusability)
```

## The Usability Pillar

The R4SUB framework organises submission-readiness evidence into four
pillars: quality, traceability, risk, and **usability**. Usability
measures how easy it is for a regulatory reviewer to understand and
navigate your submission package — a dimension that all six major
regulatory authority profiles allocate between 15 % and 20 % of the
total submission-readiness weight.

`r4subusability` implements the four indicators that make up this
pillar:

| ID    | Name                    | What it measures                           |
|-------|-------------------------|--------------------------------------------|
| U-001 | Variable Label Quality  | Label presence, length, and content        |
| U-002 | Define-XML Completeness | Origin and derivation documentation        |
| U-003 | Annotation Coverage     | Proportion of derived variables annotated  |
| U-004 | Reviewer Guide Presence | ADRG / SDRG detected in submission package |

Every assessment function returns a validated R4SUB evidence table via
[`r4subcore::as_evidence()`](https://rdrr.io/pkg/r4subcore/man/as_evidence.html),
so the output is immediately compatible with the scoring and profiling
layers.

## Configuration: `usability_config_default()`

All four indicators are driven by a shared configuration list. The
defaults reflect the most common regulatory requirements, but you can
override any element:

``` r
cfg <- usability_config_default()
str(cfg)
#> List of 5
#>  $ label_min_chars        : int 3
#>  $ label_max_chars        : int 40
#>  $ required_origins       : chr [1:2] "Derived" "Assigned"
#>  $ reviewer_guide_keywords: chr [1:5] "ADRG" "SDRG" "reviewers_guide" "reviewer_guide" ...
#>  $ weights                :List of 4
#>   ..$ label_quality      : num 0.3
#>   ..$ define_completeness: num 0.35
#>   ..$ annotation_coverage: num 0.25
#>   ..$ reviewer_guide     : num 0.1
```

Key parameters:

- `label_min_chars` / `label_max_chars` — acceptable label length window
  (default: 3–40 characters).
- `required_origins` — origins that must have a derivation text
  (`"Derived"`, `"Assigned"`).
- `reviewer_guide_keywords` — strings that identify a reviewer guide
  asset (`"ADRG"`, `"SDRG"`, `"reviewers_guide"`, `"reviewer_guide"`,
  `"ARG"`).
- `weights` — relative indicator weights summing to 1.

``` r
cfg$weights
#> $label_quality
#> [1] 0.3
#> 
#> $define_completeness
#> [1] 0.35
#> 
#> $annotation_coverage
#> [1] 0.25
#> 
#> $reviewer_guide
#> [1] 0.1
```

## Run Context

All assessment functions require a run context from `r4subcore`. A
single context object is typically created once per pipeline execution:

``` r
ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#> ℹ Run context created: "R4S-20260316112449-wl4dieex"
```

## U-001: Variable Label Quality (`assess_label_quality()`)

[`assess_label_quality()`](https://r4sub.github.io/r4subusability/reference/assess_label_quality.md)
checks every variable label for:

- **Presence** — a missing or empty label is a `fail` with
  `severity = "high"`.
- **Minimum length** — a label shorter than `label_min_chars` is a
  `warn`.
- **Maximum length** — a label longer than `label_max_chars` is a
  `warn`.
- **Otherwise** — `pass` with `severity = "info"` and
  `metric_value = 1`.

``` r
meta_labels <- data.frame(
  dataset  = c("ADSL",    "ADSL", "ADAE"),
  variable = c("USUBJID", "AGE",  "AETERM"),
  label    = c(
    "Unique Subject Identifier",  # OK — 26 chars
    "Age",                         # OK — 3 chars (at minimum)
    ""                             # fail — empty label
  ),
  stringsAsFactors = FALSE
)

ev_label <- assess_label_quality(meta_labels, ctx)
#> ✔ Evidence table created: 3 rows
ev_label[, c("location", "result", "severity", "metric_value", "message")]
#>       location result severity metric_value                message
#> 1 ADSL.USUBJID   pass     info            1      USUBJID: label OK
#> 2     ADSL.AGE   pass     info            1          AGE: label OK
#> 3  ADAE.AETERM   fail     high            0 AETERM: label is empty
```

## U-002: Define-XML Completeness (`assess_define_completeness()`)

[`assess_define_completeness()`](https://r4sub.github.io/r4subusability/reference/assess_define_completeness.md)
verifies that the Define-XML metadata is populated correctly. For
variables whose `origin` is in `required_origins`, a non-empty
`derivation` text is mandatory.

``` r
meta_define <- data.frame(
  dataset    = c("ADSL",    "ADSL",   "ADAE"),
  variable   = c("USUBJID", "AGE",    "AETERM"),
  label      = c(
    "Unique Subject Identifier",
    "Age",
    "Adverse Event Term"
  ),
  origin     = c("CRF",     "Derived", "CRF"),
  derivation = c(NA,        "Derived from BRTHDTC and RFSTDTC", NA),
  codelist   = c(NA,        NA,        NA),
  stringsAsFactors = FALSE
)

ev_define <- assess_define_completeness(meta_define, ctx)
#> ✔ Evidence table created: 3 rows
ev_define[, c("location", "result", "severity", "message")]
#>       location result severity                          message
#> 1 ADSL.USUBJID   pass     info USUBJID: origin 'CRF' documented
#> 2     ADSL.AGE   pass     info       AGE: derivation documented
#> 3  ADAE.AETERM   pass     info  AETERM: origin 'CRF' documented
```

USUBJID and AETERM come from CRF — no derivation required, both pass.
AGE is `"Derived"` and has a derivation text, so it also passes.

A variable with `origin = "Derived"` but no derivation text would fail:

``` r
meta_bad <- data.frame(
  dataset    = "ADSL",
  variable   = "TRTEDT",
  label      = "Treatment End Date",
  origin     = "Derived",
  derivation = NA_character_,
  stringsAsFactors = FALSE
)
ev_bad <- assess_define_completeness(meta_bad, ctx)
#> ✔ Evidence table created: 1 row
ev_bad[, c("location", "result", "severity", "message")]
#>      location result severity                                         message
#> 1 ADSL.TRTEDT   fail     high TRTEDT: derivation missing for origin 'Derived'
```

## U-003: Annotation Coverage (`assess_annotation_coverage()`)

[`assess_annotation_coverage()`](https://r4sub.github.io/r4subusability/reference/assess_annotation_coverage.md)
works at the **dataset level**. For each dataset it computes what
proportion of derived variables have non-empty derivation text:

- `>= 90 %` → `pass`
- `70 – 89 %` → `warn`
- `< 70 %` → `fail`

``` r
meta_annot <- data.frame(
  dataset    = c("ADSL",   "ADSL",   "ADSL",   "ADAE",   "ADAE"),
  variable   = c("AGE",    "SEX",    "TRTEDT", "AESTDTC","AEENDTC"),
  origin     = c("Derived","CRF",    "Derived","CRF",    "CRF"),
  derivation = c(
    "Derived from BRTHDTC and RFSTDTC",
    NA,                                   # CRF — not counted
    NA,                                   # Derived but not documented
    NA,                                   # CRF — not counted
    NA                                    # CRF — not counted
  ),
  stringsAsFactors = FALSE
)

ev_annot <- assess_annotation_coverage(meta_annot, ctx)
#> ✔ Evidence table created: 2 rows
ev_annot[, c("asset_id", "result", "metric_value", "message")]
#>   asset_id result metric_value                                        message
#> 1     ADSL   fail          0.5 ADSL: 50% of derived variables annotated (1/2)
#> 2     ADAE     na          1.0                     ADAE: no derived variables
```

ADSL has 2 derived variables, only 1 annotated → 50 % → `fail`. ADAE has
no derived variables so coverage is not applicable (`na`).

## U-004: Reviewer Guide Presence (`assess_reviewer_guide()`)

[`assess_reviewer_guide()`](https://r4sub.github.io/r4subusability/reference/assess_reviewer_guide.md)
checks a character vector of asset names for any keyword that matches
`reviewer_guide_keywords` (case-insensitive substring match). It returns
a single evidence row.

``` r
# Submission package includes an ADRG
ev_guide_pass <- assess_reviewer_guide(
  assets = c("ADRG", "define.xml", "datasets"),
  ctx    = ctx
)
#> ✔ Evidence table created: 1 row
ev_guide_pass[, c("result", "severity", "message")]
#>   result severity                                             message
#> 1   pass     info Reviewer guide asset detected in submission package
```

``` r
# Submission package is missing a reviewer guide
ev_guide_fail <- assess_reviewer_guide(
  assets = c("define.xml", "datasets"),
  ctx    = ctx
)
#> ✔ Evidence table created: 1 row
ev_guide_fail[, c("result", "severity", "message")]
#>   result severity                                                      message
#> 1   fail     high No reviewer guide (ADRG/SDRG) detected in submission package
```

## Master Function: `usability_indicators()`

[`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
runs all four assessments in a single call and returns one combined
evidence table:

``` r
meta_full <- data.frame(
  dataset    = c("ADSL",    "ADSL",    "ADAE"),
  variable   = c("USUBJID", "AGE",     "AETERM"),
  label      = c(
    "Unique Subject Identifier",
    "Age",
    "Adverse Event Term"
  ),
  origin     = c("CRF",     "Derived", "CRF"),
  derivation = c(NA, "Derived from BRTHDTC and RFSTDTC", NA),
  stringsAsFactors = FALSE
)

assets <- c("ADRG", "define.xml")

ev_all <- usability_indicators(meta_full, assets = assets, ctx = ctx)
#> ✔ Evidence table created: 3 rows
#> ✔ Evidence table created: 3 rows
#> ✔ Evidence table created: 2 rows
#> ✔ Evidence table created: 1 row
#> ✔ Bound 4 evidence tables: 9 total rows

# One row per variable per indicator, plus one row for the reviewer guide
nrow(ev_all)
#> [1] 9
table(ev_all$indicator_id, ev_all$result)
#>        
#>         na pass
#>   U-001  0    3
#>   U-002  0    3
#>   U-003  1    1
#>   U-004  0    1
```

## Summary and Print Method

[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
produces a structured `usability_result` object with per-indicator
pass/fail/warn counts and an overall score. The `print` method renders a
colour-coded console report:

``` r
res <- usability_summary(ev_all)
print(res)
#> 
#> ── R4SUB Usability Assessment ──
#> 
#> Study: "STUDY01" | Variables assessed: 6
#> 
#> ✓ Variable Label Quality: 100% pass (3/3)
#> ✓ Define-XML Completeness: 100% pass (3/3)
#> ✗ Annotation Coverage: 50% pass (1/2)
#> ✓ Reviewer Guide Presence: 100% pass (1/1)
#> 
#> ℹ Overall usability score: 87.5%
```

You can also access the underlying summary data frame programmatically:

``` r
res$summary[, c("indicator_id", "indicator_name", "n_pass", "n_fail", "pct_pass")]
#> # A tibble: 4 × 5
#>   indicator_id indicator_name          n_pass n_fail pct_pass
#>   <chr>        <chr>                    <int>  <int>    <dbl>
#> 1 U-001        Variable Label Quality       3      0      1  
#> 2 U-002        Define-XML Completeness      3      0      1  
#> 3 U-003        Annotation Coverage          1      0      0.5
#> 4 U-004        Reviewer Guide Presence      1      0      1
```

## Customising the Configuration

Override specific defaults without replacing the entire list:

``` r
cfg_strict <- usability_config_default()
cfg_strict$label_min_chars <- 5L   # stricter minimum length
cfg_strict$label_max_chars <- 30L  # tighter maximum

ev_strict <- assess_label_quality(meta_full, ctx, config = cfg_strict)
```

## Integration with the R4SUB Ecosystem

The evidence table returned by any `r4subusability` function plugs
directly into the rest of the R4SUB pipeline:

``` r
# Downstream — illustrative, requires r4subscore and r4subprofile
score  <- r4subscore::compute_score(ev_all)
report <- r4subprofile::render_profile(score, authority = "FDA")
```

Evidence can also be persisted for audit trails:

``` r
tmp <- tempfile(fileext = ".rds")
r4subcore::export_evidence(ev_all, tmp, format = "rds")
ev_reloaded <- r4subcore::import_evidence(tmp, format = "rds")
```
