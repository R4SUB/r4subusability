make_ctx <- function() r4subcore::r4sub_run_context(study_id = "TEST01")

make_meta <- function() {
  data.frame(
    dataset    = c("ADSL", "ADSL", "ADSL"),
    variable   = c("USUBJID", "AGE", "SEX"),
    label      = c("Unique Subject Identifier", "Age", "Sex"),
    origin     = c("CRF", "Derived", "CRF"),
    derivation = c(NA, "Derived from BRTHDTC", NA),
    codelist   = c(NA, NA, "NY"),
    stringsAsFactors = FALSE
  )
}

test_that("assess_define_completeness returns evidence tibble", {
  ev <- assess_define_completeness(make_meta(), make_ctx())
  expect_s3_class(ev, "tbl_df")
})

test_that("assess_define_completeness fails missing derivation", {
  meta <- data.frame(
    dataset = "ADSL", variable = "AGE",
    label = "Age", origin = "Derived", derivation = NA,
    stringsAsFactors = FALSE
  )
  ev <- assess_define_completeness(meta, make_ctx())
  expect_equal(ev$result, "fail")
})

test_that("assess_define_completeness passes documented derivation", {
  meta <- data.frame(
    dataset = "ADSL", variable = "AGE",
    label = "Age", origin = "Derived",
    derivation = "Derived from BRTHDTC and RFSTDTC",
    stringsAsFactors = FALSE
  )
  ev <- assess_define_completeness(meta, make_ctx())
  expect_equal(ev$result, "pass")
})

test_that("assess_define_completeness indicator_id is U-002", {
  ev <- assess_define_completeness(make_meta(), make_ctx())
  expect_true(all(ev$indicator_id == "U-002"))
})
