make_ctx <- function() r4subcore::r4sub_run_context(study_id = "TEST01")

make_meta <- function() {
  data.frame(
    dataset    = c("ADSL", "ADSL", "ADAE"),
    variable   = c("USUBJID", "AGE", "AETERM"),
    label      = c("Unique Subject Identifier", "Age", "Adverse Event Term"),
    origin     = c("CRF", "Derived", "CRF"),
    derivation = c(NA, "Derived from BRTHDTC", NA),
    stringsAsFactors = FALSE
  )
}

test_that("usability_indicators returns evidence tibble", {
  ev <- usability_indicators(make_meta(), ctx = make_ctx())
  expect_s3_class(ev, "tbl_df")
})

test_that("usability_indicators combines all 4 indicators", {
  ev <- usability_indicators(make_meta(), assets = c("ADRG"), ctx = make_ctx())
  ids <- unique(ev$indicator_id)
  expect_true(all(c("U-001", "U-002", "U-003", "U-004") %in% ids))
})

test_that("usability_indicators all rows have domain usability", {
  ev <- usability_indicators(make_meta(), ctx = make_ctx())
  expect_true(all(ev$indicator_domain == "usability"))
})

test_that("usability_summary returns usability_result", {
  ev  <- usability_indicators(make_meta(), ctx = make_ctx())
  res <- usability_summary(ev)
  expect_s3_class(res, "usability_result")
})

test_that("usability_summary print method works", {
  ev  <- usability_indicators(make_meta(), ctx = make_ctx())
  res <- usability_summary(ev)
  expect_no_error(print(res))
})
