# Fixture: spans two datasets, drives both scored results and advisory
# diagnostic findings deterministically.
#   - USUBJID: label differs ADSL vs ADAE   -> inconsistent_label
#              type Char vs Num             -> inconsistent_type
#              length 20 vs 40              -> inconsistent_length
#   - SUBJECTID: 9 characters               -> too_long (name conformance)
report_meta <- function() {
  data.frame(
    dataset    = c("ADSL", "ADSL", "ADAE", "ADAE"),
    variable   = c("USUBJID", "SUBJECTID", "USUBJID", "AETERM"),
    label      = c("Unique Subject Identifier", "Derived Subject Flag",
                   "Subject Identifier", "Reported Term"),
    origin     = c("CRF", "Derived", "CRF", "CRF"),
    derivation = c(NA, "set to 1 when enrolled", NA, NA),
    type       = c("Char", "Char", "Num", "Char"),
    length     = c(20, 8, 40, 200),
    stringsAsFactors = FALSE
  )
}

report_ctx <- function() {
  suppressMessages(r4subcore::r4sub_run_context(study_id = "RPT01"))
}

run_report <- function(..., assets = c("ADRG", "define.xml")) {
  suppressMessages(usability_report(report_meta(), assets = assets,
                                    ctx = report_ctx(), ...))
}

test_that("usability_report returns a usability_report object with the documented pieces", {
  rep <- run_report()
  expect_s3_class(rep, "usability_report")
  expect_identical(
    sort(names(rep)),
    sort(c("study_id", "n_datasets", "n_vars", "overall_score", "n_fail",
           "n_warn", "n_findings", "checks", "findings", "evidence",
           "scored", "config"))
  )
  expect_equal(rep$n_datasets, 2L)
  expect_identical(rep$study_id, "RPT01")
})

test_that("the checks tibble has one row per check with the documented columns", {
  rep <- run_report()
  expect_s3_class(rep$checks, "tbl_df")
  expect_identical(
    names(rep$checks),
    c("check", "check_name", "check_type", "n_items", "n_pass", "n_warn",
      "n_fail", "n_na", "n_findings", "pct_pass")
  )
  # Four scored indicators plus three advisory diagnostics.
  expect_equal(nrow(rep$checks), 7L)
  expect_setequal(
    rep$checks$check[rep$checks$check_type == "scored"],
    c("U-001", "U-002", "U-003", "U-004")
  )
  expect_setequal(
    rep$checks$check[rep$checks$check_type == "diagnostic"],
    c("label_consistency", "variable_name_conformance",
      "variable_attribute_consistency")
  )
})

test_that("diagnostic rows carry NA for the scored-only columns", {
  rep <- run_report()
  diag <- rep$checks[rep$checks$check_type == "diagnostic", ]
  expect_true(all(is.na(diag$n_pass)))
  expect_true(all(is.na(diag$n_warn)))
  expect_true(all(is.na(diag$n_fail)))
  expect_true(all(is.na(diag$n_na)))
  expect_true(all(is.na(diag$n_items)))
  expect_true(all(is.na(diag$pct_pass)))
  expect_true(all(!is.na(diag$n_findings)))
})

test_that("the scored summary is reproduced exactly from usability_summary (no new scoring)", {
  rep <- run_report()
  ref <- usability_summary(rep$evidence, config = rep$config)

  expect_equal(rep$overall_score, ref$overall_score)
  expect_equal(rep$n_vars, ref$n_vars)

  scored <- rep$checks[rep$checks$check_type == "scored", ]
  scored <- scored[match(ref$summary$indicator_id, scored$check), ]
  expect_equal(scored$n_pass, ref$summary$n_pass)
  expect_equal(scored$n_fail, ref$summary$n_fail)
  expect_equal(scored$n_warn, ref$summary$n_warn)
  expect_equal(scored$n_na, ref$summary$n_na)
  expect_equal(scored$pct_pass, ref$summary$pct_pass)
})

test_that("the report evidence equals the usability_indicators evidence", {
  rep <- run_report()
  ref <- suppressMessages(usability_indicators(
    report_meta(), assets = c("ADRG", "define.xml"), ctx = report_ctx()
  ))
  expect_identical(
    rep$evidence[, c("indicator_id", "result", "metric_value", "location")],
    ref[, c("indicator_id", "result", "metric_value", "location")]
  )
})

test_that("the combined findings frame harmonises every check", {
  rep <- run_report()
  expect_s3_class(rep$findings, "tbl_df")
  expect_identical(
    names(rep$findings),
    c("check", "check_type", "finding_type", "dataset", "variable", "detail")
  )
  # Every finding is attributable to a known check.
  expect_true(all(rep$findings$check_type %in% c("scored", "diagnostic")))
})

test_that("advisory diagnostic findings are counted and aggregated, never scored", {
  rep <- run_report()
  diag <- rep$checks[rep$checks$check_type == "diagnostic", ]

  n_label <- diag$n_findings[diag$check == "label_consistency"]
  n_name  <- diag$n_findings[diag$check == "variable_name_conformance"]
  n_attr  <- diag$n_findings[diag$check == "variable_attribute_consistency"]

  # USUBJID inconsistent label across ADSL/ADAE -> 2 rows.
  expect_equal(n_label, 2L)
  # SUBJECTID is 9 characters -> one too_long finding.
  expect_equal(n_name, 1L)
  # USUBJID differs on type and length -> 2 occurrences x 2 attributes.
  expect_equal(n_attr, 4L)

  expect_equal(rep$n_findings, n_label + n_name + n_attr)

  diag_findings <- rep$findings[rep$findings$check_type == "diagnostic", ]
  expect_setequal(
    unique(diag_findings$finding_type),
    c("inconsistent_label", "too_long", "inconsistent_type",
      "inconsistent_length")
  )
})

test_that("scored warn/fail rows become findings; a missing reviewer guide fails", {
  rep <- run_report(assets = character(0))
  scored_findings <- rep$findings[rep$findings$check_type == "scored", ]
  guide <- scored_findings[scored_findings$check == "U-004", ]
  expect_equal(nrow(guide), 1L)
  expect_identical(guide$finding_type, "fail")
  expect_true(is.na(guide$variable))
})

test_that("a fully clean submission yields no scored findings", {
  rep <- run_report()
  # The fixture passes every scored indicator (reviewer guide present).
  expect_equal(sum(rep$checks$n_fail[rep$checks$check_type == "scored"],
                   na.rm = TRUE), 0L)
  expect_false("scored" %in% rep$findings$check_type)
})

test_that("diagnostics = FALSE reports only the scored indicators", {
  rep <- run_report(diagnostics = FALSE)
  expect_equal(nrow(rep$checks), 4L)
  expect_true(all(rep$checks$check_type == "scored"))
  expect_equal(rep$n_findings, 0L)
  expect_false("diagnostic" %in% rep$findings$check_type)
})

test_that("the overall score is identical whether or not diagnostics run", {
  with_diag    <- run_report(diagnostics = TRUE)
  without_diag <- run_report(diagnostics = FALSE)
  # Diagnostics are descriptive only: they never move the scored roll-up.
  expect_equal(with_diag$overall_score, without_diag$overall_score)
})

test_that("print returns the object invisibly", {
  rep <- run_report()
  expect_no_error(suppressMessages(print(rep)))
  out <- withVisible(suppressMessages(print(rep)))
  expect_false(out$visible)
  expect_identical(out$value, rep)
})

test_that("invalid arguments are rejected", {
  expect_error(
    usability_report(report_meta(), ctx = "not a context"),
    "run context"
  )
  expect_error(
    suppressMessages(usability_report(report_meta(), ctx = report_ctx(),
                                      diagnostics = NA)),
    "diagnostics"
  )
})

test_that("runs end to end on real r4subdata metadata", {
  skip_if_not_installed("r4subdata")
  ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "ONCO"))
  rep <- suppressMessages(usability_report(
    r4subdata::oncology_metadata,
    assets = c("ADRG", "define.xml"),
    ctx = ctx
  ))
  expect_s3_class(rep, "usability_report")
  expect_equal(nrow(rep$checks), 7L)
  expect_true(is.numeric(rep$overall_score))
  expect_gte(rep$overall_score, 0)
  expect_lte(rep$overall_score, 1)

  # The scored roll-up matches a direct usability_summary of the same evidence.
  ref <- usability_summary(rep$evidence)
  expect_equal(rep$overall_score, ref$overall_score)

  # Evidence is the validated R4SUB table from the scored indicators.
  expect_silent(r4subcore::validate_evidence(rep$evidence))
  expect_setequal(unique(rep$evidence$indicator_id),
                  c("U-001", "U-002", "U-003", "U-004"))
})
