test_that("variable_attribute_consistency returns a tibble with expected columns", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Char"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_s3_class(out, "tbl_df")
  expect_identical(
    names(out),
    c("finding_type", "variable", "dataset", "attribute", "value", "detail")
  )
})

test_that("consistent attributes yield zero findings", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Char"),
    length   = c(20, 20),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("an inconsistent type is flagged once per affected dataset", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("AGE", "AGE"),
    type     = c("Num", "Char"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  typ <- out[out$finding_type == "inconsistent_type", ]
  expect_equal(nrow(typ), 2L)
  expect_setequal(typ$dataset, c("ADSL", "ADAE"))
  expect_setequal(typ$value, c("Num", "Char"))
  expect_true(all(typ$attribute == "type"))
})

test_that("an inconsistent length is flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    length   = c(20, 40),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_true("inconsistent_length" %in% out$finding_type)
  expect_setequal(out$value, c("20", "40"))
})

test_that("a variable differing on two attributes appears under two finding types", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Num"),
    length   = c(20, 40),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_setequal(
    unique(out$finding_type),
    c("inconsistent_type", "inconsistent_length")
  )
})

test_that("a variable in only one dataset is never flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("AGE", "AETERM"),
    type     = c("Num", "Char"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("NA and empty attribute values are treated as missing", {
  # USUBJID has a type in ADSL but NA/empty elsewhere -> only one present
  # value, so no inconsistency is reported.
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = c("USUBJID", "USUBJID", "USUBJID"),
    type     = c("Char", NA, ""),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("whitespace differences do not create false findings", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", " Char "),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("only requested attributes present in metadata are checked", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Num"),
    length   = c(20, 40),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta, attributes = "type")
  expect_true(all(out$attribute == "type"))
  expect_false("inconsistent_length" %in% out$finding_type)
})

test_that("requesting an absent attribute yields zero findings, not an error", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Num"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta, attributes = "format")
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

test_that("missing required columns raise an error", {
  bad <- data.frame(dataset = "ADSL", stringsAsFactors = FALSE)
  expect_error(variable_attribute_consistency(bad), "missing columns")
})

test_that("invalid attributes argument raises an error", {
  meta <- data.frame(
    dataset = "ADSL", variable = "X", type = "Char",
    stringsAsFactors = FALSE
  )
  expect_error(variable_attribute_consistency(meta, attributes = character(0)))
  expect_error(variable_attribute_consistency(meta, attributes = NA_character_))
  expect_error(variable_attribute_consistency(meta, attributes = 1))
})

test_that("runs on real r4subdata metadata and returns the documented shape", {
  skip_if_not_installed("r4subdata")
  out <- variable_attribute_consistency(r4subdata::adam_metadata)
  expect_s3_class(out, "tbl_df")
  expect_identical(
    names(out),
    c("finding_type", "variable", "dataset", "attribute", "value", "detail")
  )
  # Whatever is reported must concern variables that span >1 dataset.
  if (nrow(out) > 0L) {
    for (v in unique(out$variable)) {
      n_ds <- length(unique(
        r4subdata::adam_metadata$dataset[r4subdata::adam_metadata$variable == v]
      ))
      expect_gt(n_ds, 1L)
    }
  }
})
