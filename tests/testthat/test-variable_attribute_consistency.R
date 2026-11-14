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

# ---------------------------------------------------------------------------
# Drift in each attribute independently, and all three together
# ---------------------------------------------------------------------------

test_that("an inconsistent format is flagged independently", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("ADT", "ADT"),
    format   = c("DATE9.", "DATE11."),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 2L)
  expect_true(all(out$finding_type == "inconsistent_format"))
  expect_true(all(out$attribute == "format"))
  expect_setequal(out$value, c("DATE9.", "DATE11."))
})

test_that("drift in type, length and format together yields all three finding types", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("X", "X"),
    type     = c("Char", "Num"),
    length   = c(8, 20),
    format   = c("$8.", "BEST."),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  # Two occurrences per drifting attribute, three attributes -> six rows.
  expect_equal(nrow(out), 6L)
  expect_setequal(
    unique(out$finding_type),
    c("inconsistent_type", "inconsistent_length", "inconsistent_format")
  )
  # Each attribute contributes exactly two rows (one per dataset occurrence).
  expect_equal(as.integer(table(out$attribute)[c("type", "length", "format")]),
               c(2L, 2L, 2L))
})

# ---------------------------------------------------------------------------
# A variable spanning 3+ datasets with partial drift
# ---------------------------------------------------------------------------

test_that("partial drift across three datasets flags every occurrence", {
  # Consistent in ADSL and ADAE (length 20), drifts in ADLB (length 40).
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = "USUBJID",
    length   = c(20, 20, 40),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 3L)
  expect_true(all(out$finding_type == "inconsistent_length"))
  expect_setequal(out$dataset, c("ADSL", "ADAE", "ADLB"))
  # The two distinct values both appear, and the detail reports "2 distinct".
  expect_setequal(out$value, c("20", "40"))
  expect_true(all(grepl("2 distinct length values", out$detail)))
})

# ---------------------------------------------------------------------------
# NA vs empty-string vs whitespace-only each treated as missing, with
# genuine drift still reported among the present values.
# ---------------------------------------------------------------------------

test_that("NA is treated as missing while real drift among present values is reported", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = "AGE",
    type     = c("Num", "Char", NA),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 2L)
  expect_setequal(out$dataset, c("ADSL", "ADAE"))
  expect_false("ADLB" %in% out$dataset)
})

test_that("empty string is treated as missing while real drift is reported", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = "AGE",
    type     = c("Num", "Char", ""),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 2L)
  expect_setequal(out$dataset, c("ADSL", "ADAE"))
  expect_false("ADLB" %in% out$dataset)
})

test_that("whitespace-only is treated as missing while real drift is reported", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = "AGE",
    type     = c("Num", "Char", "   "),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  expect_equal(nrow(out), 2L)
  expect_setequal(out$dataset, c("ADSL", "ADAE"))
  expect_false("ADLB" %in% out$dataset)
})

# ---------------------------------------------------------------------------
# A requested attribute absent from metadata is skipped, present ones checked
# ---------------------------------------------------------------------------

test_that("a requested attribute absent from metadata is skipped without error", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Num"),
    stringsAsFactors = FALSE
  )
  # "format" and "length" are absent; only "type" can be checked.
  out <- variable_attribute_consistency(
    meta, attributes = c("type", "length", "format")
  )
  expect_equal(nrow(out), 2L)
  expect_true(all(out$attribute == "type"))
})

# ---------------------------------------------------------------------------
# A variable in only one of several datasets is never flagged
# ---------------------------------------------------------------------------

test_that("a variable present in only one of three datasets is never flagged", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE", "ADLB"),
    variable = c("USUBJID", "USUBJID", "AELLT"),
    type     = c("Char", "Char", "Char"),
    length   = c(20, 20, 200),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  # AELLT appears only in ADLB; USUBJID is consistent -> nothing flagged.
  expect_equal(nrow(out), 0L)
})

# ---------------------------------------------------------------------------
# Configurable multi-attribute subset
# ---------------------------------------------------------------------------

test_that("a multi-attribute subset checks only the named attributes", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("USUBJID", "USUBJID"),
    type     = c("Char", "Num"),
    length   = c(20, 40),
    format   = c("$20.", "$40."),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta, attributes = c("type", "format"))
  expect_setequal(
    unique(out$finding_type),
    c("inconsistent_type", "inconsistent_format")
  )
  expect_false("inconsistent_length" %in% out$finding_type)
  expect_false("length" %in% out$attribute)
})

# ---------------------------------------------------------------------------
# Exact output shape and row content for a known input
# ---------------------------------------------------------------------------

test_that("exact rows and ordering are produced for a known input", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("AGE", "AGE"),
    type     = c("Num", "Char"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)

  expect_equal(nrow(out), 2L)
  expect_identical(
    names(out),
    c("finding_type", "variable", "dataset", "attribute", "value", "detail")
  )
  # Rows are ordered by finding_type, variable, then dataset (ADAE < ADSL).
  expect_identical(out$dataset, c("ADAE", "ADSL"))
  expect_identical(out$value, c("Char", "Num"))
  expect_true(all(out$finding_type == "inconsistent_type"))
  expect_true(all(out$variable == "AGE"))
  expect_true(all(out$attribute == "type"))
  # The detail names the variable, the local value, and the other dataset.
  expect_match(out$detail[1], "variable 'AGE'")
  expect_match(out$detail[1], "here 'Char' in ADAE")
  expect_match(out$detail[1], "ADSL='Num'")
})

# ---------------------------------------------------------------------------
# Real r4subdata metadata: internally consistent, and drift is detected
# ---------------------------------------------------------------------------

test_that("adam_metadata shared variables are internally consistent", {
  skip_if_not_installed("r4subdata")
  out <- variable_attribute_consistency(r4subdata::adam_metadata)
  # The shipped ADaM metadata uses consistent attributes for shared keys.
  expect_equal(nrow(out), 0L)
})

test_that("injected drift in real metadata is detected and isolated", {
  skip_if_not_installed("r4subdata")
  md <- as.data.frame(r4subdata::adam_metadata)
  hit <- which(md$dataset == "ADAE" & md$variable == "USUBJID")
  expect_length(hit, 1L)
  md$length[hit] <- 999L

  out <- variable_attribute_consistency(md)
  expect_gt(nrow(out), 0L)
  # Only USUBJID drifts; nothing else should be reported.
  expect_true(all(out$variable == "USUBJID"))
  expect_true(all(out$finding_type == "inconsistent_length"))
  expect_true("999" %in% out$value)
})

# ---------------------------------------------------------------------------
# Advisory only: emits no evidence and does not touch U-001..U-004 scores
# ---------------------------------------------------------------------------

test_that("the report carries no R4SUB evidence columns", {
  meta <- data.frame(
    dataset  = c("ADSL", "ADAE"),
    variable = c("AGE", "AGE"),
    type     = c("Num", "Char"),
    stringsAsFactors = FALSE
  )
  out <- variable_attribute_consistency(meta)
  # It is purely descriptive: none of the scored-indicator columns appear.
  expect_false(any(
    c("indicator_id", "result", "metric_value", "severity") %in% names(out)
  ))
})

test_that("running the diagnostic does not alter U-001..U-004 scores", {
  skip_if_not_installed("r4subdata")
  skip_if_not_installed("r4subcore")
  ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
  # The scored indicators need origin/derivation; oncology_metadata carries them.
  md <- r4subdata::oncology_metadata

  before <- suppressMessages(usability_indicators(
    md, assets = c("ADRG", "define.xml"), ctx = ctx
  ))
  # Call the advisory diagnostic in between.
  invisible(variable_attribute_consistency(md))
  after <- suppressMessages(usability_indicators(
    md, assets = c("ADRG", "define.xml"), ctx = ctx
  ))

  expect_identical(
    before[, c("indicator_id", "result", "metric_value")],
    after[, c("indicator_id", "result", "metric_value")]
  )
  expect_setequal(unique(before$indicator_id),
                  c("U-001", "U-002", "U-003", "U-004"))
})
