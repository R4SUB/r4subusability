make_ctx <- function() r4subcore::r4sub_run_context(study_id = "TEST01")

test_that("assess_annotation_coverage returns evidence tibble", {
  meta <- data.frame(
    dataset    = c("ADSL", "ADSL"),
    variable   = c("AGE", "SEX"),
    origin     = c("Derived", "CRF"),
    derivation = c("Derived from BRTHDTC", NA),
    stringsAsFactors = FALSE
  )
  ev <- assess_annotation_coverage(meta, make_ctx())
  expect_s3_class(ev, "tbl_df")
})

test_that("assess_annotation_coverage one row per dataset", {
  meta <- data.frame(
    dataset    = c("ADSL", "ADSL", "ADAE"),
    variable   = c("AGE", "SEX", "AEDECOD"),
    origin     = c("Derived", "CRF", "Derived"),
    derivation = c("Derived from BRTHDTC", NA, NA),
    stringsAsFactors = FALSE
  )
  ev <- assess_annotation_coverage(meta, make_ctx())
  expect_equal(nrow(ev), 2L)
})

test_that("assess_annotation_coverage metric_value between 0 and 1", {
  meta <- data.frame(
    dataset    = "ADSL",
    variable   = c("AGE", "TRT01P"),
    origin     = c("Derived", "Derived"),
    derivation = c("Derived from BRTHDTC", NA),
    stringsAsFactors = FALSE
  )
  ev <- assess_annotation_coverage(meta, make_ctx())
  expect_gte(ev$metric_value, 0)
  expect_lte(ev$metric_value, 1)
})
