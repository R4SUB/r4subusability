#' Diagnose Variable Label Consistency
#'
#' Produces a descriptive, tidy report of label-consistency problems in variable
#' metadata. Unlike [assess_label_quality()] (indicator U-001), this function
#' does not score or emit R4SUB evidence rows; it is a diagnostic aid that
#' surfaces three classes of finding:
#'
#' \describe{
#'   \item{`duplicate_label`}{Two or more variables in the *same* dataset share
#'     an identical (non-empty) label.}
#'   \item{`inconsistent_label`}{A variable name that appears in more than one
#'     dataset carries different labels across those datasets.}
#'   \item{`missing_table_label`}{A dataset has no dataset-level (table) label.
#'     Only checked when a `table_label` column is supplied.}
#' }
#'
#' Comparisons ignore leading and trailing white space. Empty strings and `NA`
#' are treated as missing labels and never counted as duplicates or
#' inconsistencies.
#'
#' @param metadata A data frame with at least columns `dataset` (character),
#'   `variable` (character), and `label` (character). An optional `table_label`
#'   column (character) supplies the dataset-level label used for the
#'   `missing_table_label` check.
#'
#' @return A tibble with one row per finding and the columns:
#'   \describe{
#'     \item{finding_type}{One of `"duplicate_label"`, `"inconsistent_label"`,
#'       or `"missing_table_label"`.}
#'     \item{dataset}{The dataset the finding relates to.}
#'     \item{variable}{The variable the finding relates to, or `NA` for a
#'       dataset-level finding.}
#'     \item{label}{The variable label involved, or `NA` where not applicable.}
#'     \item{detail}{A human-readable description of the finding.}
#'   }
#'   When there are no findings, a zero-row tibble with the same columns is
#'   returned.
#'
#' @seealso [assess_label_quality()] for the scored U-001 indicator.
#'
#' @examples
#' meta <- data.frame(
#'   dataset  = c("ADSL", "ADSL", "ADAE", "ADAE"),
#'   variable = c("USUBJID", "SUBJID", "USUBJID", "AETERM"),
#'   label    = c("Subject ID", "Subject ID",
#'                "Unique Subject Identifier", "Reported Term"),
#'   stringsAsFactors = FALSE
#' )
#' label_consistency(meta)
#'
#' # With a dataset-level (table) label column
#' meta2 <- data.frame(
#'   dataset     = c("ADSL", "ADAE"),
#'   variable    = c("USUBJID", "USUBJID"),
#'   label       = c("Unique Subject Identifier", "Unique Subject Identifier"),
#'   table_label = c("Subject-Level Analysis Dataset", ""),
#'   stringsAsFactors = FALSE
#' )
#' label_consistency(meta2)
#'
#' @export
label_consistency <- function(metadata) {
  metadata <- as.data.frame(metadata)

  required_cols <- c("dataset", "variable", "label")
  missing <- setdiff(required_cols, names(metadata))
  if (length(missing) > 0L) {
    cli::cli_abort("metadata is missing columns: {.field {missing}}")
  }

  dataset  <- as.character(metadata$dataset)
  variable <- as.character(metadata$variable)
  label    <- trimws(as.character(metadata$label))
  label[is.na(metadata$label)] <- NA_character_
  has_label <- !is.na(label) & nchar(label) > 0L

  empty_findings <- function() {
    tibble::tibble(
      finding_type = character(0),
      dataset      = character(0),
      variable     = character(0),
      label        = character(0),
      detail       = character(0)
    )
  }

  findings <- list()

  # 1. Duplicate labels within a dataset -------------------------------------
  if (any(has_label)) {
    key <- paste(dataset, label, sep = "\r")
    dup_key <- key %in% key[duplicated(key)] & has_label
    for (i in which(dup_key)) {
      peers <- variable[dataset == dataset[i] & label == label[i] &
                          has_label & variable != variable[i]]
      peers <- unique(peers)
      findings[[length(findings) + 1L]] <- data.frame(
        finding_type = "duplicate_label",
        dataset      = dataset[i],
        variable     = variable[i],
        label        = label[i],
        detail       = paste0(
          "label '", label[i], "' also used by: ",
          paste(sort(peers), collapse = ", ")
        ),
        stringsAsFactors = FALSE
      )
    }
  }

  # 2. Same variable, inconsistent labels across datasets --------------------
  for (v in unique(variable)) {
    idx <- which(variable == v & has_label)
    if (length(idx) == 0L) next
    distinct_labels <- unique(label[idx])
    if (length(distinct_labels) > 1L) {
      for (i in idx) {
        others <- idx[dataset[idx] != dataset[i] | label[idx] != label[i]]
        detail <- paste0(
          "variable '", v, "' has ", length(distinct_labels),
          " distinct labels across datasets; here '", label[i],
          "', elsewhere: ",
          paste(sort(unique(
            paste0(dataset[others], "='", label[others], "'")
          )), collapse = ", ")
        )
        findings[[length(findings) + 1L]] <- data.frame(
          finding_type = "inconsistent_label",
          dataset      = dataset[i],
          variable     = v,
          label        = label[i],
          detail       = detail,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # 3. Missing dataset-level (table) labels ----------------------------------
  if ("table_label" %in% names(metadata)) {
    tbl_label <- trimws(as.character(metadata$table_label))
    tbl_label[is.na(metadata$table_label)] <- NA_character_
    for (ds in unique(dataset)) {
      ds_labels <- tbl_label[dataset == ds]
      present <- ds_labels[!is.na(ds_labels) & nchar(ds_labels) > 0L]
      if (length(present) == 0L) {
        findings[[length(findings) + 1L]] <- data.frame(
          finding_type = "missing_table_label",
          dataset      = ds,
          variable     = NA_character_,
          label        = NA_character_,
          detail       = paste0("dataset '", ds,
                                 "' has no dataset-level (table) label"),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(findings) == 0L) {
    return(empty_findings())
  }

  out <- do.call(rbind, findings)
  out <- out[order(out$finding_type, out$dataset,
                   is.na(out$variable), out$variable), , drop = FALSE]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
