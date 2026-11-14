#' Diagnose Cross-Dataset Variable Attribute Consistency
#'
#' Produces a descriptive, tidy report of variables whose data **attributes**
#' drift across the datasets in which they appear. A variable name that is used
#' in more than one dataset (for example `USUBJID` in `ADSL` and `ADAE`) is
#' expected to carry the same data type, storage length, and display format
#' everywhere; a mismatch is a common, objective source of reviewer friction
#' and a frequent cause of transport-file surprises.
#'
#' Like [label_consistency()] and [variable_name_conformance()], and unlike the
#' scored usability indicators (for example [assess_label_quality()]), this
#' function does not score anything or emit R4SUB evidence rows; it is a purely
#' advisory diagnostic. The result is tidy: one row per affected dataset
#' occurrence per attribute, so a variable that differs on both type and length
#' appears under two finding types. The following finding types may be emitted,
#' one per checked attribute column that is present in `metadata`:
#'
#' \describe{
#'   \item{`inconsistent_type`}{The `type` attribute differs across datasets.}
#'   \item{`inconsistent_length`}{The `length` attribute differs across
#'     datasets.}
#'   \item{`inconsistent_format`}{The `format` attribute differs across
#'     datasets.}
#' }
#'
#' Only the attribute columns named in `attributes` that are actually present in
#' `metadata` are checked; requested attributes that are absent are silently
#' skipped, so the function is safe to call on metadata that carries only some
#' of them. Values are compared after trimming leading and trailing white space;
#' `NA` and empty-string values are treated as missing and never drive a
#' finding, so a variable that simply lacks (say) a format in one dataset is not
#' reported.
#'
#' @param metadata A data frame with at least columns `dataset` (character) and
#'   `variable` (character), plus any of the attribute columns named in
#'   `attributes`. Compatible with the `adam_metadata`, `sdtm_metadata`, and
#'   `oncology_metadata` datasets from `r4subdata`.
#' @param attributes A character vector naming the attribute columns to check
#'   for cross-dataset consistency. Defaults to `c("type", "length", "format")`.
#'   Any name not present in `metadata` is skipped.
#'
#' @return A tibble with one row per finding and the columns:
#'   \describe{
#'     \item{finding_type}{One of `"inconsistent_type"`,
#'       `"inconsistent_length"`, or `"inconsistent_format"` (one per checked
#'       attribute).}
#'     \item{variable}{The variable whose attribute is inconsistent.}
#'     \item{dataset}{The dataset this row reports.}
#'     \item{attribute}{The name of the attribute column involved.}
#'     \item{value}{The attribute value this variable carries in this dataset
#'       (as character).}
#'     \item{detail}{A human-readable description of the finding.}
#'   }
#'   When every shared variable is consistent, a zero-row tibble with the same
#'   columns is returned.
#'
#' @seealso [label_consistency()] for label-level consistency and
#'   [variable_name_conformance()] for name conformance.
#'
#' @examples
#' meta <- data.frame(
#'   dataset  = c("ADSL", "ADAE", "ADSL", "ADAE"),
#'   variable = c("USUBJID", "USUBJID", "AGE", "AGE"),
#'   type     = c("Char", "Char", "Num", "Char"),
#'   length   = c(20, 40, 8, 8),
#'   stringsAsFactors = FALSE
#' )
#' # USUBJID differs in length; AGE differs in type.
#' variable_attribute_consistency(meta)
#'
#' # Restrict the check to a single attribute.
#' variable_attribute_consistency(meta, attributes = "type")
#'
#' @export
variable_attribute_consistency <- function(metadata,
                                           attributes = c("type", "length",
                                                          "format")) {
  metadata <- as.data.frame(metadata)

  required_cols <- c("dataset", "variable")
  missing <- setdiff(required_cols, names(metadata))
  if (length(missing) > 0L) {
    cli::cli_abort("metadata is missing columns: {.field {missing}}")
  }

  if (!is.character(attributes) || length(attributes) == 0L ||
      anyNA(attributes) || any(nchar(attributes) == 0L)) {
    cli::cli_abort(
      "{.arg attributes} must be a non-empty character vector of column names."
    )
  }

  empty_findings <- function() {
    tibble::tibble(
      finding_type = character(0),
      variable     = character(0),
      dataset      = character(0),
      attribute    = character(0),
      value        = character(0),
      detail       = character(0)
    )
  }

  # Only attributes actually present in the metadata can be checked.
  attributes <- unique(attributes)
  attributes <- attributes[attributes %in% names(metadata)]
  if (length(attributes) == 0L) {
    return(empty_findings())
  }

  dataset  <- as.character(metadata$dataset)
  variable <- as.character(metadata$variable)

  findings <- list()

  for (attr in attributes) {
    raw   <- metadata[[attr]]
    value <- trimws(as.character(raw))
    value[is.na(raw)] <- NA_character_
    present <- !is.na(value) & nchar(value) > 0L

    for (v in unique(variable)) {
      idx <- which(variable == v & present)
      if (length(idx) == 0L) next

      # A variable must span more than one dataset to be "inconsistent".
      if (length(unique(dataset[idx])) < 2L) next

      distinct_values <- unique(value[idx])
      if (length(distinct_values) <= 1L) next

      for (i in idx) {
        others <- idx[dataset[idx] != dataset[i] | value[idx] != value[i]]
        elsewhere <- sort(unique(
          paste0(dataset[others], "='", value[others], "'")
        ))
        detail <- paste0(
          "variable '", v, "' has ", length(distinct_values),
          " distinct ", attr, " values across datasets; here '",
          value[i], "' in ", dataset[i], ", elsewhere: ",
          paste(elsewhere, collapse = ", ")
        )
        findings[[length(findings) + 1L]] <- data.frame(
          finding_type = paste0("inconsistent_", attr),
          variable     = v,
          dataset      = dataset[i],
          attribute    = attr,
          value        = value[i],
          detail       = detail,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(findings) == 0L) {
    return(empty_findings())
  }

  out <- do.call(rbind, findings)
  out <- out[order(out$finding_type, out$variable, out$dataset), ,
             drop = FALSE]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
