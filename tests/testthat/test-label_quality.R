make_ctx <- function() r4subcore::r4sub_run_context(study_id = "TEST01")

make_meta <- function() {
  data.frame(
    dataset  = c("ADSL", "ADSL", "ADAE"),
    variable = c("USUBJID", "AGE", "AETERM"),
    label    = c("Unique Subject Identifier", "Age", ""),
    stringsAsFactors = FALSE
  )
}

test_that("assess_label_quality returns evidence tibble", {
  ev <- assess_label_quality(make_meta(), make_ctx())
  expect_s3_class(ev, "tbl_df")
})

test_that("assess_label_quality returns one row per variable", {
  meta <- make_meta()
  ev   <- assess_label_quality(meta, make_ctx())
  expect_equal(nrow(ev), nrow(meta))
})

test_that("assess_label_quality fails empty labels", {
  ev    <- assess_label_quality(make_meta(), make_ctx())
  empty <- ev[ev$location == "ADAE.AETERM", ]
  expect_equal(empty$result, "fail")
})

test_that("assess_label_quality passes good labels", {
  ev   <- assess_label_quality(make_meta(), make_ctx())
  good <- ev[ev$location == "ADSL.USUBJID", ]
  expect_equal(good$result, "pass")
})

test_that("assess_label_quality indicator_domain is usability", {
  ev <- assess_label_quality(make_meta(), make_ctx())
  expect_true(all(ev$indicator_domain == "usability"))
})

test_that("assess_label_quality errors on missing columns", {
  bad <- data.frame(dataset = "ADSL", stringsAsFactors = FALSE)
  expect_error(assess_label_quality(bad, make_ctx()))
})
