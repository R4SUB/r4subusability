# Case study: reviewer experience from ADaM metadata

A submission can be technically correct and still be hard to review.
Missing labels, undocumented derivations, thin annotations, and a
missing reviewer guide all slow a reviewer down, and a slow review is a
risk. `r4subusability` scores this reviewer experience directly, on the
same evidence footing as quality and risk.

This case study builds a Define-XML style metadata view from the example
CDISC pilot metadata in `r4subdata`, then measures it.

``` r

library(r4subusability)
library(r4subdata)
```

## Building a Define-style view

The usability checks read metadata with an `origin` and, for derived
variables, a `derivation`. The example ADaM metadata does not carry
those yet, but the trace mapping does: a direct copy is a predecessor,
anything with a real derivation rule is derived. Joining the two gives a
realistic Define-style table.

``` r

meta <- adam_metadata

key <- paste(meta$dataset, meta$variable)
mk  <- paste(trace_mapping$adam_dataset, trace_mapping$adam_var)
idx <- match(key, mk)
has <- !is.na(idx)
deriv <- trace_mapping$derivation_text[idx]

meta$origin <- "Assigned"
meta$origin[has & grepl("Direct copy", deriv)]  <- "Predecessor"
meta$origin[has & !grepl("Direct copy", deriv)] <- "Derived"
meta$derivation <- NA_character_
meta$derivation[has] <- deriv[has]

head(meta[, c("dataset", "variable", "label", "origin", "derivation")], 6)
#> # A tibble: 6 × 5
#>   dataset variable label                     origin      derivation             
#>   <chr>   <chr>    <chr>                     <chr>       <chr>                  
#> 1 ADSL    STUDYID  Study Identifier          Predecessor Direct copy from DM.ST…
#> 2 ADSL    USUBJID  Unique Subject Identifier Predecessor Direct copy from DM.US…
#> 3 ADSL    SUBJID   Subject Identifier        Predecessor Direct copy from DM.SU…
#> 4 ADSL    SITEID   Study Site Identifier     Predecessor Direct copy from DM.SI…
#> 5 ADSL    AGE      Age                       Predecessor Direct copy from DM.AGE
#> 6 ADSL    AGEU     Age Units                 Predecessor Direct copy from DM.AG…
```

## Measuring usability

[`usability_indicators()`](https://r4sub.github.io/r4subusability/reference/usability_indicators.md)
runs the four checks and returns evidence rows. The `assets` argument is
the list of submission documents present, which is how the reviewer
guide check knows whether the guide was shipped.

``` r

ctx <- r4subcore::r4sub_run_context(study_id = "CDISCPILOT01",
                                    environment = "UAT")
#> ℹ Run context created: "R4S-20260805052258-wl4dieex"

ev <- usability_indicators(
  meta,
  assets = c("adrg.pdf", "define.xml"),
  ctx = ctx
)
#> ✔ Evidence table created: 36 rows
#> ✔ Evidence table created: 36 rows
#> ✔ Evidence table created: 3 rows
#> ✔ Evidence table created: 1 row
#> ✔ Bound 4 evidence tables: 76 total rows

nrow(ev)
#> [1] 76
table(ev$indicator_name, ev$result)
#>                          
#>                           fail pass
#>   Annotation Coverage        3    0
#>   Define-XML Completeness   11   25
#>   Reviewer Guide Presence    0    1
#>   Variable Label Quality     0   36
```

## Reading the result

[`usability_summary()`](https://r4sub.github.io/r4subusability/reference/usability_summary.md)
turns those rows into the reviewer-facing picture: pass rates per check
and an overall usability score.

``` r

usability_summary(ev)
#> 
#> ── R4SUB Usability Assessment ──
#> 
#> Study: "CDISCPILOT01" | Variables assessed: 36
#> 
#> ✓ Variable Label Quality: 100% pass (36/36)
#> ✗ Define-XML Completeness: 69.4% pass (25/36)
#> ✗ Annotation Coverage: 0% pass (0/3)
#> ✓ Reviewer Guide Presence: 100% pass (1/1)
#> 
#> ℹ Overall usability score: 64.3%
```

The pattern here is typical. Labels are complete and the reviewer guide
is present, but annotation coverage on derived variables is thin. That
is a precise, actionable finding: document the derivations for the
variables the check flags, and the score moves.

## Where it goes

These rows are ordinary R4SUB evidence. They flow into the Usability
pillar of the Submission Confidence Index next to quality, trace, and
risk. Reviewer experience stops being a soft concern raised late and
becomes a measured input to the readiness decision.
