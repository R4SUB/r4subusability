test_that("label_consistency returns a tibble with the expected columns", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "AETERM"),
    label    = c("Unique Subject Identifier", "Reported Term"),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  expect_s3_class(out, "tbl_df")
  expect_identical(
    names(out),
    c("finding_type", "dataset", "variable", "label", "detail")
  )
})

test_that("clean metadata yields zero findings", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "AETERM"),
    label    = c("Unique Subject Identifier", "Reported Term"),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("duplicate labels within a dataset are flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADSL"),
    variable = c("USUBJID", "SUBJID"),
    label    = c("Subject ID", "Subject ID"),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  dup <- out[out$finding_type == "duplicate_label", ]
  expect_equal(nrow(dup), 2L)
  expect_true(all(dup$dataset == "ADSL"))
  expect_true(grepl("SUBJID", dup$detail[dup$variable == "USUBJID"]))
})

test_that("inconsistent labels for the same variable across datasets are flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    label    = c("Unique Subject Identifier", "Subject ID"),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  inc <- out[out$finding_type == "inconsistent_label", ]
  expect_equal(nrow(inc), 2L)
  expect_setequal(inc$dataset, c("ADSL", "ADAE"))
})

test_that("consistent labels for a shared variable are not flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    label    = c("Unique Subject Identifier", "Unique Subject Identifier"),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("missing table labels are flagged only when table_label is supplied", {
  meta <- data.frame(
    dataset     = c("ADSL", "ADAE"),
    variable    = c("USUBJID", "USUBJID"),
    label       = c("Unique Subject Identifier", "Unique Subject Identifier"),
    table_label = c("Subject-Level Analysis Dataset", ""),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  mt <- out[out$finding_type == "missing_table_label", ]
  expect_equal(nrow(mt), 1L)
  expect_equal(mt$dataset, "ADAE")
  expect_true(is.na(mt$variable))

  # Without the column, no table-label findings.
  out2 <- label_consistency(meta[, c("dataset", "variable", "label")])
  expect_equal(sum(out2$finding_type == "missing_table_label"), 0L)
})

test_that("empty and NA labels are treated as missing, not duplicates", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADSL", "ADSL"),
    variable = c("V1", "V2", "V3"),
    label    = c("", NA, "  "),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  expect_equal(nrow(out), 0L)
})

test_that("whitespace differences do not hide duplicates", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADSL"),
    variable = c("V1", "V2"),
    label    = c("Age", " Age "),
    stringsAsFactors = FALSE
  )
  out <- label_consistency(meta)
  expect_equal(sum(out$finding_type == "duplicate_label"), 2L)
})

test_that("missing required columns raise an error", {
  bad <- data.frame(dataset = "ADSL", stringsAsFactors = FALSE)
  expect_error(label_consistency(bad))
})
