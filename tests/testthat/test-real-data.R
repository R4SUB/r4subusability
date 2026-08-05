# Tests driven by the real pharma metadata in r4subdata.

skip_if_not_installed("r4subdata")

rd_ctx <- function() {
  suppressMessages(r4subcore::r4sub_run_context(study_id = "ONCO-2025-001"))
}

test_that("label quality runs on adam_metadata and validates", {
  ev <- suppressMessages(assess_label_quality(r4subdata::adam_metadata, rd_ctx()))
  expect_s3_class(ev, "data.frame")
  expect_equal(nrow(ev), nrow(r4subdata::adam_metadata))
  expect_silent(r4subcore::validate_evidence(ev))
  expect_true(all(ev$indicator_id == "U-001"))
})

test_that("define completeness runs on oncology_metadata and validates", {
  ev <- suppressMessages(
    assess_define_completeness(r4subdata::oncology_metadata, rd_ctx())
  )
  expect_true(all(ev$indicator_id == "U-002"))
  expect_silent(r4subcore::validate_evidence(ev))
})

test_that("annotation coverage returns one row per dataset", {
  ev <- suppressMessages(
    assess_annotation_coverage(r4subdata::oncology_metadata, rd_ctx())
  )
  n_ds <- length(unique(r4subdata::oncology_metadata$dataset))
  expect_equal(nrow(ev), n_ds)
  expect_true(all(ev$metric_value >= 0 & ev$metric_value <= 1))
})

test_that("full pipeline and summary produce a weighted score on real data", {
  ev <- suppressMessages(usability_indicators(
    r4subdata::oncology_metadata,
    assets = c("ADRG", "define.xml"),
    ctx = rd_ctx()
  ))
  res <- usability_summary(ev)

  expect_s3_class(res, "usability_result")
  expect_true(is.numeric(res$overall_score))
  expect_gte(res$overall_score, 0)
  expect_lte(res$overall_score, 1)

  # n_vars counts only the variable-level (U-001/U-002) locations.
  var_locs <- length(unique(
    ev$location[ev$indicator_id %in% c("U-001", "U-002")]
  ))
  expect_equal(res$n_vars, var_locs)

  # pct_pass excludes "na" rows from the denominator.
  for (i in seq_len(nrow(res$summary))) {
    row <- res$summary[i, ]
    appl <- row$n_total - row$n_na
    if (appl > 0) expect_equal(row$pct_pass, row$n_pass / appl)
  }
})
