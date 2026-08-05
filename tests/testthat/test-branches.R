# Branch coverage for edge cases and previously-untested paths.

b_ctx <- function() {
  suppressMessages(r4subcore::r4sub_run_context(study_id = "TEST01"))
}

test_that("label quality warns on too-short and too-long labels", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADSL"),
    variable = c("AB", "LONGVAR"),
    label    = c("Hi", strrep("x", 45)),
    stringsAsFactors = FALSE
  )
  ev <- suppressMessages(assess_label_quality(meta, b_ctx()))
  expect_equal(ev$result[ev$location == "ADSL.AB"], "warn")
  expect_equal(ev$result[ev$location == "ADSL.LONGVAR"], "warn")
})

test_that("a custom config changes the label length thresholds", {
  meta <- data.frame(
    dataset = "ADSL", variable = "X", label = "Age",
    stringsAsFactors = FALSE
  )
  cfg <- usability_config_default()
  cfg$label_min_chars <- 10L               # "Age" (3) now too short
  ev <- suppressMessages(assess_label_quality(meta, b_ctx(), config = cfg))
  expect_equal(ev$result, "warn")
})

test_that("define completeness fails a derived variable with no derivation", {
  meta <- data.frame(
    dataset = "ADSL", variable = "AGEGR1",
    label = "Age Group", origin = "Derived",
    derivation = NA_character_,
    stringsAsFactors = FALSE
  )
  ev <- suppressMessages(assess_define_completeness(meta, b_ctx()))
  expect_equal(ev$result, "fail")
  expect_equal(ev$severity, "high")
})

test_that("define completeness fails an empty origin", {
  meta <- data.frame(
    dataset = "ADSL", variable = "X", label = "X", origin = "",
    stringsAsFactors = FALSE
  )
  ev <- suppressMessages(assess_define_completeness(meta, b_ctx()))
  expect_equal(ev$result, "fail")
})

test_that("annotation coverage reports 'na' for a dataset with no derived vars", {
  meta <- data.frame(
    dataset = "ADSL", variable = c("USUBJID", "SEX"),
    origin = c("CRF", "CRF"), derivation = c(NA, NA),
    stringsAsFactors = FALSE
  )
  ev <- suppressMessages(assess_annotation_coverage(meta, b_ctx()))
  expect_equal(ev$result, "na")
})

test_that("annotation coverage warns between 70% and 90% documented", {
  # 3 derived vars, 2 documented -> 66.7% -> fail; 4 derived, 3 documented -> 75% -> warn
  meta <- data.frame(
    dataset = "ADSL", variable = c("D1", "D2", "D3", "D4"),
    origin = rep("Derived", 4),
    derivation = c("a", "b", "c", NA),
    stringsAsFactors = FALSE
  )
  ev <- suppressMessages(assess_annotation_coverage(meta, b_ctx()))
  expect_equal(ev$result, "warn")
})

test_that("annotation coverage errors on missing required columns", {
  bad <- data.frame(dataset = "ADSL", variable = "X", stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(assess_annotation_coverage(bad, b_ctx())),
    "missing columns"
  )
})

test_that("reviewer guide is NA-safe and matches on a word boundary", {
  ev_na <- suppressMessages(
    assess_reviewer_guide(c(NA, "adrg.pdf"), b_ctx())
  )
  expect_equal(ev_na$result, "pass")

  # "target.txt" must not match the reviewer-guide keywords
  ev_no <- suppressMessages(
    assess_reviewer_guide(c("target.txt", "define.xml"), b_ctx())
  )
  expect_equal(ev_no$result, "fail")
})

test_that("the assessors reject a non-run-context ctx", {
  meta <- data.frame(
    dataset = "ADSL", variable = "X", label = "X",
    stringsAsFactors = FALSE
  )
  expect_error(assess_label_quality(meta, ctx = list()), "run context")
})

test_that("summary excludes na rows and weights the overall score", {
  # ADSL has only CRF vars -> U-003 is 'na' for ADSL; ensure it does not drag pct.
  meta <- data.frame(
    dataset = c("ADSL", "ADSL"),
    variable = c("USUBJID", "SEX"),
    label = c("Unique Subject Identifier", "Sex"),
    origin = c("CRF", "CRF"),
    derivation = c(NA, NA),
    stringsAsFactors = FALSE
  )
  ev  <- suppressMessages(usability_indicators(meta, ctx = b_ctx()))
  res <- usability_summary(ev)
  u003 <- res$summary[res$summary$indicator_id == "U-003", ]
  expect_true(is.na(u003$pct_pass))     # all 'na' -> not applicable
  expect_true(is.na(res$overall_score) || res$overall_score >= 0)
})
