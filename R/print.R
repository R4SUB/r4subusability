#' Print a Usability Result Summary
#'
#' @param x A `usability_result` object returned by [usability_summary()].
#' @param ... Ignored.
#'
#' @return Invisibly returns `x`. Called for its side effect of printing a
#'   summary of usability indicator scores (pass/fail/warn counts and overall
#'   proportion) to the console.
#'
#' @export
print.usability_result <- function(x, ...) {
  cli::cli_h2("R4SUB Usability Assessment")
  cli::cli_text("Study: {.val {x$study_id}}  |  Variables assessed: {.val {x$n_vars}}")
  cli::cli_text("")

  for (i in seq_len(nrow(x$summary))) {
    row <- x$summary[i, ]
    pct <- round(row$pct_pass * 100, 1)
    if (pct >= 90) icon <- cli::col_green("\u2713")
    else if (pct >= 70) icon <- cli::col_yellow("!")
    else icon <- cli::col_red("\u2717")
    cli::cli_text("{icon} {row$indicator_name}: {pct}% pass ({row$n_pass}/{row$n_total})")
  }

  overall <- round(mean(x$summary$pct_pass) * 100, 1)
  cli::cli_text("")
  cli::cli_alert_info("Overall usability score: {overall}%")
  invisible(x)
}

#' Summarise Usability Evidence
#'
#' Produces a structured summary of usability evidence, suitable for printing
#' or for passing to downstream reporting functions.
#'
#' @param evidence A validated evidence tibble from [usability_indicators()] or
#'   any of the individual assessment functions.
#'
#' @return A `usability_result` list (class `"usability_result"`) with:
#'   \describe{
#'     \item{study_id}{The study identifier from the evidence.}
#'     \item{n_vars}{Number of unique variable locations assessed.}
#'     \item{summary}{A tibble with per-indicator pass/fail/warn counts and
#'       `pct_pass` (proportion of passing rows).}
#'     \item{evidence}{The original evidence tibble.}
#'   }
#'
#' @examples
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' meta <- data.frame(
#'   dataset  = c("ADSL", "ADSL"),
#'   variable = c("USUBJID", "AGE"),
#'   label    = c("Unique Subject Identifier", "Age"),
#'   origin   = c("CRF", "Derived"),
#'   derivation = c(NA, "Derived from BRTHDTC"),
#'   stringsAsFactors = FALSE
#' )
#' ev  <- usability_indicators(meta, ctx = ctx)
#' res <- usability_summary(ev)
#' print(res)
#'
#' @export
usability_summary <- function(evidence) {
  indicator_ids   <- unique(evidence$indicator_id)
  indicator_names <- unique(evidence[, c("indicator_id", "indicator_name")])

  rows <- lapply(indicator_ids, function(id) {
    sub     <- evidence[evidence$indicator_id == id, ]
    n_total <- nrow(sub)
    n_pass  <- sum(sub$result == "pass", na.rm = TRUE)
    n_fail  <- sum(sub$result == "fail", na.rm = TRUE)
    n_warn  <- sum(sub$result == "warn", na.rm = TRUE)
    name    <- indicator_names$indicator_name[indicator_names$indicator_id == id][1L]

    tibble::tibble(
      indicator_id   = id,
      indicator_name = name,
      n_total        = n_total,
      n_pass         = n_pass,
      n_fail         = n_fail,
      n_warn         = n_warn,
      pct_pass       = if (n_total > 0L) n_pass / n_total else NA_real_
    )
  })

  summary_tbl <- do.call(rbind, rows)

  result <- list(
    study_id = unique(evidence$study_id)[1L],
    n_vars   = length(unique(evidence$location)),
    summary  = summary_tbl,
    evidence = evidence
  )
  class(result) <- "usability_result"
  result
}
