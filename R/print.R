# Internal: map indicator ids to their configured weight names.
indicator_weight <- function(ids, config) {
  map <- c("U-001" = "label_quality", "U-002" = "define_completeness",
           "U-003" = "annotation_coverage", "U-004" = "reviewer_guide")
  vapply(ids, function(id) {
    key <- unname(map[id])
    if (is.na(key)) return(0)
    w <- config$weights[[key]]
    if (is.null(w)) 0 else as.numeric(w)
  }, numeric(1))
}

#' Print a Usability Result Summary
#'
#' @param x A `usability_result` object returned by [usability_summary()].
#' @param ... Ignored.
#'
#' @return Invisibly returns `x`. Called for its side effect of printing a
#'   summary of usability indicator scores (pass/fail/warn counts and the
#'   weighted overall score) to the console.
#'
#' @export
print.usability_result <- function(x, ...) {
  cli::cli_h2("R4SUB Usability Assessment")
  cli::cli_text("Study: {.val {x$study_id}}  |  Variables assessed: {.val {x$n_vars}}")
  cli::cli_text("")

  for (i in seq_len(nrow(x$summary))) {
    row <- x$summary[i, ]
    if (is.na(row$pct_pass)) {
      cli::cli_text("- {row$indicator_name}: not applicable")
      next
    }
    pct    <- round(row$pct_pass * 100, 1)
    n_appl <- row$n_total - row$n_na
    if (pct >= 90) {
      icon <- cli::col_green("\u2713")
    } else if (pct >= 70) {
      icon <- cli::col_yellow("!")
    } else {
      icon <- cli::col_red("\u2717")
    }
    cli::cli_text("{icon} {row$indicator_name}: {pct}% pass ({row$n_pass}/{n_appl})")
  }

  cli::cli_text("")
  if (is.na(x$overall_score)) {
    cli::cli_alert_info("Overall usability score: not available")
  } else {
    cli::cli_alert_info("Overall usability score: {round(x$overall_score * 100, 1)}%")
  }
  invisible(x)
}

#' Summarise Usability Evidence
#'
#' Produces a structured summary of usability evidence, suitable for printing
#' or for passing to downstream reporting functions.
#'
#' @param evidence A validated evidence tibble from [usability_indicators()] or
#'   any of the individual assessment functions.
#' @param config A configuration list from [usability_config_default()], used
#'   for the per-indicator weights in the overall score. If `NULL` the default
#'   configuration is used.
#'
#' @return A `usability_result` list (class `"usability_result"`) with:
#'   \describe{
#'     \item{study_id}{The study identifier from the evidence.}
#'     \item{n_vars}{Number of unique variable-level locations assessed (the
#'       label and Define completeness checks).}
#'     \item{overall_score}{The weighted mean of the per-indicator pass
#'       proportions, using the configuration weights; `NA` if nothing is
#'       applicable.}
#'     \item{summary}{A tibble with per-indicator pass/fail/warn/na counts and
#'       `pct_pass` (passing rows over applicable rows, excluding `"na"`).}
#'     \item{evidence}{The original evidence tibble.}
#'   }
#'
#' @examplesIf requireNamespace("r4subdata", quietly = TRUE)
#' ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
#' ev  <- suppressMessages(
#'   usability_indicators(r4subdata::oncology_metadata, ctx = ctx)
#' )
#' res <- usability_summary(ev)
#' print(res)
#'
#' @export
usability_summary <- function(evidence, config = NULL) {
  if (is.null(config)) config <- usability_config_default()

  indicator_ids   <- unique(evidence$indicator_id)
  indicator_names <- unique(evidence[, c("indicator_id", "indicator_name")])

  rows <- lapply(indicator_ids, function(id) {
    sub     <- evidence[evidence$indicator_id == id, ]
    n_total <- nrow(sub)
    n_pass  <- sum(sub$result == "pass", na.rm = TRUE)
    n_fail  <- sum(sub$result == "fail", na.rm = TRUE)
    n_warn  <- sum(sub$result == "warn", na.rm = TRUE)
    n_na    <- sum(sub$result == "na", na.rm = TRUE)
    n_appl  <- n_total - n_na
    name    <- indicator_names$indicator_name[indicator_names$indicator_id == id][1L]

    tibble::tibble(
      indicator_id   = id,
      indicator_name = name,
      n_total        = n_total,
      n_pass         = n_pass,
      n_fail         = n_fail,
      n_warn         = n_warn,
      n_na           = n_na,
      pct_pass       = if (n_appl > 0L) n_pass / n_appl else NA_real_
    )
  })

  summary_tbl <- do.call(rbind, rows)

  # Weighted overall score across indicators that have applicable rows.
  w <- indicator_weight(summary_tbl$indicator_id, config)
  usable <- !is.na(summary_tbl$pct_pass) & w > 0
  overall <- if (any(usable)) {
    sum(summary_tbl$pct_pass[usable] * w[usable]) / sum(w[usable])
  } else {
    NA_real_
  }

  # Count only variable-level locations (label and Define checks), not the
  # dataset-level (U-003) or package-level (U-004) rows.
  var_rows <- evidence[evidence$indicator_id %in% c("U-001", "U-002"), ]
  n_vars   <- length(unique(var_rows$location))

  structure(
    list(
      study_id      = unique(evidence$study_id)[1L],
      n_vars        = n_vars,
      overall_score = overall,
      summary       = summary_tbl,
      evidence      = evidence
    ),
    class = "usability_result"
  )
}
