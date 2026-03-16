make_ctx <- function() r4subcore::r4sub_run_context(study_id = "TEST01")

test_that("assess_reviewer_guide passes when ADRG present", {
  ev <- assess_reviewer_guide(c("ADRG", "define.xml"), make_ctx())
  expect_equal(ev$result, "pass")
})

test_that("assess_reviewer_guide fails when no guide present", {
  ev <- assess_reviewer_guide(c("define.xml", "datasets"), make_ctx())
  expect_equal(ev$result, "fail")
})

test_that("assess_reviewer_guide returns single row", {
  ev <- assess_reviewer_guide(c("SDRG"), make_ctx())
  expect_equal(nrow(ev), 1L)
})

test_that("assess_reviewer_guide indicator_id is U-004", {
  ev <- assess_reviewer_guide(character(0), make_ctx())
  expect_equal(ev$indicator_id, "U-004")
})

test_that("assess_reviewer_guide is case-insensitive", {
  ev <- assess_reviewer_guide(c("adrg"), make_ctx())
  expect_equal(ev$result, "pass")
})
