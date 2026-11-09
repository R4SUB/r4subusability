test_that("variable_name_conformance returns a tibble with the expected columns", {
  out <- variable_name_conformance(c("USUBJID", "AETERM"))
  expect_s3_class(out, "tbl_df")
  expect_identical(names(out), c("name", "reason", "detail"))
})

test_that("fully conforming names yield zero findings", {
  out <- variable_name_conformance(c("USUBJID", "AETERM", "TRT01P", "_X", "A1"))
  expect_equal(nrow(out), 0L)
})

test_that("names longer than the limit are flagged as too_long", {
  out <- variable_name_conformance(c("SUBJECTID", "USUBJID"))
  too_long <- out[out$reason == "too_long", ]
  expect_equal(nrow(too_long), 1L)
  expect_equal(too_long$name, "SUBJECTID")
})

test_that("lower-case letters are invalid under the default rule", {
  out <- variable_name_conformance("trt01p")
  expect_true("invalid_character" %in% out$reason)
  expect_true(grepl("trp", out$detail[out$reason == "invalid_character"]))
})

test_that("names starting with a digit are flagged", {
  out <- variable_name_conformance("2VISIT")
  expect_true("starts_with_digit" %in% out$reason)
})

test_that("allow_leading_digit suppresses the digit finding", {
  out <- variable_name_conformance("2VISIT", allow_leading_digit = TRUE)
  expect_false("starts_with_digit" %in% out$reason)
})

test_that("a single name can break more than one rule (tidy long output)", {
  # 'ae-term99' is >8 chars, contains '-' and lower case, but no leading digit
  out <- variable_name_conformance("ae-term99")
  expect_setequal(out$reason, c("too_long", "invalid_character"))
  expect_true(all(out$name == "ae-term99"))
})

test_that("empty, whitespace, and NA names are reported as empty", {
  out <- variable_name_conformance(c("", "  ", NA_character_))
  expect_equal(nrow(out), 3L)
  expect_true(all(out$reason == "empty"))
})

test_that("limits are configurable", {
  # A longer limit and a case-insensitive character set make lower-case
  # long names conform.
  out <- variable_name_conformance(
    "SubjectIdentifier",
    max_length = 32L,
    allowed_chars = "A-Za-z0-9_"
  )
  expect_equal(nrow(out), 0L)
})

test_that("a data frame is checked by its column names", {
  df <- data.frame(USUBJID = 1, AgeInYears = 2, check.names = FALSE)
  out <- variable_name_conformance(df)
  expect_true("AgeInYears" %in% out$name)
  expect_false("USUBJID" %in% out$name)
})

test_that("an empty input yields a zero-row tibble", {
  out <- variable_name_conformance(character(0))
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

test_that("invalid configuration arguments raise an error", {
  expect_error(variable_name_conformance("X", max_length = 0))
  expect_error(variable_name_conformance("X", allowed_chars = ""))
  expect_error(variable_name_conformance("X", allow_leading_digit = NA))
})
