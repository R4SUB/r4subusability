#' Check Variable and Dataset Names Against SAS v5 Transport Constraints
#'
#' Produces a descriptive, tidy report of names that do not conform to the
#' SAS Version 5 transport (XPT) format naming constraints that still govern
#' many regulatory submissions. By default a conforming name is at most eight
#' characters long, is built only from upper-case letters, digits, and the
#' underscore, and does not start with a digit.
#'
#' Unlike the scored usability indicators (for example
#' [assess_label_quality()]), this function does not score anything or emit
#' R4SUB evidence rows; it is a purely advisory diagnostic. Every reported
#' name may appear on more than one row when it breaks more than one rule, so
#' the result is tidy (one row per name per reason). The following reasons are
#' emitted:
#'
#' \describe{
#'   \item{`too_long`}{The name is longer than `max_length` characters.}
#'   \item{`invalid_character`}{The name contains at least one character
#'     outside the set described by `allowed_chars`.}
#'   \item{`starts_with_digit`}{The first character of the name is a digit.
#'     Suppressed when `allow_leading_digit = TRUE`.}
#'   \item{`empty`}{The name is `NA`, empty, or white space only.}
#' }
#'
#' The limits are configurable so the same function can check other naming
#' conventions (for example a longer SAS V8/V9 limit, or a case-insensitive
#' character set). The defaults encode the documented SAS v5 rule.
#'
#' @param names A character vector of names to check, or a data frame whose
#'   column names are checked. Anything else is coerced with [as.character()].
#' @param max_length Maximum allowed name length, in characters. Defaults to
#'   `8L`, the SAS v5 transport limit.
#' @param allowed_chars A regular-expression character-class body describing
#'   the permitted characters (the text that would appear between `[` and `]`).
#'   Defaults to `"A-Z0-9_"`: upper-case letters, digits, and the underscore.
#'   Use, for example, `"A-Za-z0-9_"` to also permit lower-case letters.
#' @param allow_leading_digit Logical; when `FALSE` (the default) a name that
#'   begins with a digit is reported as `starts_with_digit`.
#'
#' @return A tibble with one row per non-conforming name per reason, and the
#'   columns:
#'   \describe{
#'     \item{name}{The non-conforming name.}
#'     \item{reason}{One of `"too_long"`, `"invalid_character"`,
#'       `"starts_with_digit"`, or `"empty"`.}
#'     \item{detail}{A human-readable description of the finding.}
#'   }
#'   When every name conforms, a zero-row tibble with the same columns is
#'   returned.
#'
#' @seealso [assess_label_quality()] for the scored U-001 indicator.
#'
#' @examples
#' # A character vector of variable names
#' variable_name_conformance(
#'   c("USUBJID", "SUBJECTID", "trt01p", "2VISIT", "AE_TERM")
#' )
#'
#' # Check the column names of a data frame directly
#' df <- data.frame(USUBJID = 1, AgeInYears = 2, check.names = FALSE)
#' variable_name_conformance(df)
#'
#' # Configurable limits: allow lower case and a longer (V8) limit
#' variable_name_conformance(
#'   c("trt01p", "SUBJECTIDENTIFIER"),
#'   max_length = 32L,
#'   allowed_chars = "A-Za-z0-9_"
#' )
#'
#' @export
variable_name_conformance <- function(names,
                                      max_length = 8L,
                                      allowed_chars = "A-Z0-9_",
                                      allow_leading_digit = FALSE) {
  if (is.data.frame(names)) {
    nms <- names(names)
  } else {
    nms <- as.character(names)
  }

  if (!is.numeric(max_length) || length(max_length) != 1L ||
      is.na(max_length) || max_length < 1) {
    cli::cli_abort("{.arg max_length} must be a single positive number.")
  }
  if (!is.character(allowed_chars) || length(allowed_chars) != 1L ||
      is.na(allowed_chars) || nchar(allowed_chars) == 0L) {
    cli::cli_abort("{.arg allowed_chars} must be a single non-empty string.")
  }
  if (!is.logical(allow_leading_digit) || length(allow_leading_digit) != 1L ||
      is.na(allow_leading_digit)) {
    cli::cli_abort("{.arg allow_leading_digit} must be a single `TRUE`/`FALSE`.")
  }

  empty_findings <- function() {
    tibble::tibble(
      name   = character(0),
      reason = character(0),
      detail = character(0)
    )
  }

  if (length(nms) == 0L) {
    return(empty_findings())
  }

  allowed_regex <- paste0("^[", allowed_chars, "]+$")
  findings <- list()

  add <- function(name, reason, detail) {
    findings[[length(findings) + 1L]] <<- data.frame(
      name   = name,
      reason = reason,
      detail = detail,
      stringsAsFactors = FALSE
    )
  }

  for (nm in nms) {
    trimmed <- if (is.na(nm)) NA_character_ else trimws(nm)
    is_empty <- is.na(trimmed) || nchar(trimmed) == 0L

    if (is_empty) {
      add(if (is.na(nm)) NA_character_ else nm,
          "empty",
          "name is missing, empty, or white space only")
      next
    }

    n <- nchar(nm)
    if (n > max_length) {
      add(nm, "too_long",
          paste0("name has ", n, " characters; exceeds maximum of ",
                 max_length))
    }

    if (!grepl(allowed_regex, nm)) {
      offending <- gsub(paste0("[", allowed_chars, "]"), "", nm)
      offending_chars <- unique(strsplit(offending, "")[[1]])
      add(nm, "invalid_character",
          paste0("name contains characters outside the allowed set [",
                 allowed_chars, "]: ",
                 paste(offending_chars, collapse = "")))
    }

    if (!allow_leading_digit && grepl("^[0-9]", nm)) {
      add(nm, "starts_with_digit", "name starts with a digit")
    }
  }

  if (length(findings) == 0L) {
    return(empty_findings())
  }

  out <- do.call(rbind, findings)
  out <- out[order(out$name, out$reason), , drop = FALSE]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
