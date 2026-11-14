# Internal: the harmonised column set of the combined findings frame.
usability_findings_cols <- function() {
  c("check", "check_type", "finding_type", "dataset", "variable", "detail")
}

# Internal: a zero-row combined findings tibble with the documented columns.
empty_usability_findings <- function() {
  tibble::tibble(
    check        = character(0),
    check_type   = character(0),
    finding_type = character(0),
    dataset      = character(0),
    variable     = character(0),
    detail       = character(0)
  )
}

# Internal: turn the warn/fail evidence rows of the scored indicators into
# harmonised finding rows. The scored indicators own the pass/warn/fail
# semantics; this only reshapes the rows they already flagged.
scored_findings <- function(evidence) {
  offending <- evidence[evidence$result %in% c("warn", "fail"), , drop = FALSE]
  if (nrow(offending) == 0L) return(empty_usability_findings())

  asset    <- as.character(offending$asset_id)
  location <- as.character(offending$location)
  # location is "<dataset>.<variable>" for variable-level rows and just the
  # asset id for dataset-/package-level rows; recover the variable only when a
  # "<asset>." prefix is actually present.
  variable <- ifelse(
    location == asset,
    NA_character_,
    sub("^[^.]*\\.", "", location)
  )

  tibble::tibble(
    check        = as.character(offending$indicator_id),
    check_type   = "scored",
    finding_type = as.character(offending$result),
    dataset      = asset,
    variable     = variable,
    detail       = as.character(offending$message)
  )
}

# Internal: the advisory diagnostics the report orchestrates, each reshaped to
# the harmonised findings columns. Returns a named list of tibbles (or NULL for
# a diagnostic that could not run on the supplied metadata).
run_usability_diagnostics <- function(metadata) {
  variables <- unique(as.character(metadata$variable))

  specs <- list(
    label_consistency = function() {
      f <- label_consistency(metadata)
      tibble::tibble(
        check        = "label_consistency",
        check_type   = "diagnostic",
        finding_type = as.character(f$finding_type),
        dataset      = as.character(f$dataset),
        variable     = as.character(f$variable),
        detail       = as.character(f$detail)
      )
    },
    variable_name_conformance = function() {
      f <- variable_name_conformance(variables)
      tibble::tibble(
        check        = "variable_name_conformance",
        check_type   = "diagnostic",
        finding_type = as.character(f$reason),
        dataset      = NA_character_,
        variable     = as.character(f$name),
        detail       = as.character(f$detail)
      )
    },
    variable_attribute_consistency = function() {
      f <- variable_attribute_consistency(metadata)
      tibble::tibble(
        check        = "variable_attribute_consistency",
        check_type   = "diagnostic",
        finding_type = as.character(f$finding_type),
        dataset      = as.character(f$dataset),
        variable     = as.character(f$variable),
        detail       = as.character(f$detail)
      )
    }
  )

  lapply(specs, function(run) {
    tryCatch(run(), error = function(e) NULL)
  })
}

# Internal: human-readable names for the diagnostics, in report order.
usability_diagnostic_names <- function() {
  c(
    label_consistency              = "Label Consistency",
    variable_name_conformance      = "Variable Name Conformance",
    variable_attribute_consistency = "Variable Attribute Consistency"
  )
}

#' Consolidated Usability Report
#'
#' Runs every usability check the package provides over one metadata frame in a
#' single call and assembles the results into one coherent report. It is a pure
#' orchestration and aggregation layer: it invents **no** new pass/warn/fail
#' criteria, thresholds, or scores. The scored indicators keep their own
#' U-001..U-004 semantics and weighted roll-up (from [usability_summary()]), and
#' the advisory diagnostics keep their descriptive, unscored finding counts.
#'
#' Two families of check are combined:
#'
#' \describe{
#'   \item{Scored indicators}{[assess_label_quality()] (U-001),
#'     [assess_define_completeness()] (U-002), [assess_annotation_coverage()]
#'     (U-003), and [assess_reviewer_guide()] (U-004), run together through
#'     [usability_indicators()]. These emit validated R4SUB evidence and carry
#'     pass/warn/fail/na results and a weighted overall score.}
#'   \item{Advisory diagnostics}{[label_consistency()],
#'     [variable_name_conformance()] (run over the distinct variable names), and
#'     [variable_attribute_consistency()]. These are descriptive: they report a
#'     tidy set of findings and are never scored or rolled into the overall
#'     score.}
#' }
#'
#' The overall usability score is exactly the weighted score from
#' [usability_summary()] over the four scored indicators; the diagnostics
#' contribute only finding counts, never a pass/fail judgement.
#'
#' @param metadata A data frame with columns `dataset`, `variable`, `label`,
#'   `origin`, `derivation` (optional), and `codelist` (optional). May span
#'   several datasets (one row per variable per dataset). Compatible with the
#'   `adam_metadata`, `sdtm_metadata`, and `oncology_metadata` datasets from
#'   `r4subdata`.
#' @param assets A character vector of asset names present in the submission
#'   package, passed to [assess_reviewer_guide()]. Defaults to `character(0)`.
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#' @param diagnostics Logical; when `TRUE` (the default) the advisory
#'   diagnostics are run and aggregated alongside the scored indicators. When
#'   `FALSE` only the scored indicators are reported.
#'
#' @return A `usability_report` object (a list with class `"usability_report"`)
#'   with:
#'   \describe{
#'     \item{study_id}{The study identifier from the evidence.}
#'     \item{n_datasets}{Number of distinct datasets in `metadata`.}
#'     \item{n_vars}{Number of variable-level locations assessed (as counted by
#'       [usability_summary()]).}
#'     \item{overall_score}{The weighted scored-indicator score from
#'       [usability_summary()]; `NA` when nothing is applicable.}
#'     \item{n_fail,n_warn}{Total `fail` and `warn` rows across the scored
#'       indicators.}
#'     \item{n_findings}{Total number of advisory diagnostic findings.}
#'     \item{checks}{A tidy per-check summary tibble: one row per check with
#'       `check`, `check_name`, `check_type` (`"scored"` or `"diagnostic"`),
#'       `n_items`, `n_pass`, `n_warn`, `n_fail`, `n_na`, `n_findings`, and
#'       `pct_pass`. Scored-only columns are `NA` for diagnostics.}
#'     \item{findings}{A combined tidy tibble of the offending items across all
#'       checks, with columns `check`, `check_type`, `finding_type`, `dataset`,
#'       `variable`, and `detail`.}
#'     \item{evidence}{The combined R4SUB evidence tibble from the scored
#'       indicators (see [r4subcore::as_evidence()]).}
#'     \item{scored}{The [usability_summary()] result for the scored
#'       indicators.}
#'     \item{config}{The configuration used.}
#'   }
#'
#' @seealso [usability_indicators()] and [usability_summary()] for the scored
#'   indicators; [label_consistency()], [variable_name_conformance()], and
#'   [variable_attribute_consistency()] for the advisory diagnostics.
#'
#' @examplesIf requireNamespace("r4subdata", quietly = TRUE)
#' ctx <- suppressMessages(r4subcore::r4sub_run_context(study_id = "STUDY01"))
#' rep <- suppressMessages(usability_report(
#'   r4subdata::oncology_metadata,
#'   assets = c("ADRG", "define.xml"),
#'   ctx = ctx
#' ))
#' rep$checks
#' print(rep)
#'
#' @export
usability_report <- function(metadata, assets = character(0), ctx,
                             config = NULL, diagnostics = TRUE) {
  if (is.null(config)) config <- usability_config_default()
  assert_run_context(ctx)
  if (!is.logical(diagnostics) || length(diagnostics) != 1L ||
      is.na(diagnostics)) {
    cli::cli_abort("{.arg diagnostics} must be a single `TRUE`/`FALSE`.")
  }
  metadata <- as.data.frame(metadata)

  # 1. Scored indicators (authoritative; emit R4SUB evidence) ---------------
  evidence <- usability_indicators(metadata, assets = assets, ctx = ctx,
                                   config = config)
  scored   <- usability_summary(evidence, config = config)

  scored_checks <- data.frame(
    check      = scored$summary$indicator_id,
    check_name = scored$summary$indicator_name,
    check_type = "scored",
    n_items    = as.integer(scored$summary$n_total),
    n_pass     = as.integer(scored$summary$n_pass),
    n_warn     = as.integer(scored$summary$n_warn),
    n_fail     = as.integer(scored$summary$n_fail),
    n_na       = as.integer(scored$summary$n_na),
    n_findings = as.integer(scored$summary$n_warn + scored$summary$n_fail),
    pct_pass   = as.numeric(scored$summary$pct_pass),
    stringsAsFactors = FALSE
  )

  findings_list <- list(scored_findings(evidence))

  # 2. Advisory diagnostics (descriptive; never scored) ---------------------
  diag_checks <- NULL
  if (isTRUE(diagnostics)) {
    diag_out  <- run_usability_diagnostics(metadata)
    diag_name <- usability_diagnostic_names()

    diag_checks <- do.call(rbind, lapply(names(diag_name), function(key) {
      f <- diag_out[[key]]
      n_find <- if (is.null(f)) NA_integer_ else nrow(f)
      if (!is.null(f) && nrow(f) > 0L) {
        findings_list[[length(findings_list) + 1L]] <<- f
      }
      data.frame(
        check      = key,
        check_name = unname(diag_name[key]),
        check_type = "diagnostic",
        n_items    = NA_integer_,
        n_pass     = NA_integer_,
        n_warn     = NA_integer_,
        n_fail     = NA_integer_,
        n_na       = NA_integer_,
        n_findings = n_find,
        pct_pass   = NA_real_,
        stringsAsFactors = FALSE
      )
    }))
  }

  checks <- rbind(scored_checks, diag_checks)
  rownames(checks) <- NULL
  checks <- tibble::as_tibble(checks)

  findings <- do.call(rbind, findings_list)
  if (is.null(findings) || nrow(findings) == 0L) {
    findings <- empty_usability_findings()
  } else {
    rownames(findings) <- NULL
    findings <- tibble::as_tibble(findings)
  }

  n_diag_findings <- if (isTRUE(diagnostics)) {
    sum(diag_checks$n_findings, na.rm = TRUE)
  } else {
    0L
  }

  structure(
    list(
      study_id      = scored$study_id,
      n_datasets    = length(unique(as.character(metadata$dataset))),
      n_vars        = scored$n_vars,
      overall_score = scored$overall_score,
      n_fail        = sum(scored_checks$n_fail),
      n_warn        = sum(scored_checks$n_warn),
      n_findings    = as.integer(n_diag_findings),
      checks        = checks,
      findings      = findings,
      evidence      = evidence,
      scored        = scored,
      config        = config
    ),
    class = "usability_report"
  )
}

#' Print a Consolidated Usability Report
#'
#' @param x A `usability_report` object returned by [usability_report()].
#' @param ... Ignored.
#'
#' @return Invisibly returns `x`. Called for its side effect of printing the
#'   scored-indicator pass rates, the weighted overall score, and the advisory
#'   diagnostic finding counts to the console.
#'
#' @export
print.usability_report <- function(x, ...) {
  cli::cli_h2("R4SUB Usability Report")
  cli::cli_text(
    "Study: {.val {x$study_id}}  |  Datasets: {.val {x$n_datasets}}  |  ",
    "Variables assessed: {.val {x$n_vars}}"
  )

  scored <- x$checks[x$checks$check_type == "scored", , drop = FALSE]
  if (nrow(scored) > 0L) {
    cli::cli_text("")
    cli::cli_text("Scored indicators")
    for (i in seq_len(nrow(scored))) {
      row <- scored[i, ]
      if (is.na(row$pct_pass)) {
        cli::cli_text("- {row$check_name}: not applicable")
        next
      }
      pct    <- round(row$pct_pass * 100, 1)
      n_appl <- row$n_items - row$n_na
      if (pct >= 90) {
        icon <- cli::col_green("\u2713")
      } else if (pct >= 70) {
        icon <- cli::col_yellow("!")
      } else {
        icon <- cli::col_red("\u2717")
      }
      cli::cli_text(
        "{icon} {row$check_name}: {pct}% pass ({row$n_pass}/{n_appl})"
      )
    }
  }

  diag <- x$checks[x$checks$check_type == "diagnostic", , drop = FALSE]
  if (nrow(diag) > 0L) {
    cli::cli_text("")
    cli::cli_text("Advisory diagnostics (descriptive, unscored)")
    for (i in seq_len(nrow(diag))) {
      row <- diag[i, ]
      if (is.na(row$n_findings)) {
        cli::cli_text("- {row$check_name}: not run")
      } else if (row$n_findings == 0L) {
        cli::cli_text("{cli::col_green('\u2713')} {row$check_name}: no findings")
      } else {
        cli::cli_text(
          "{cli::col_yellow('!')} {row$check_name}: ",
          "{row$n_findings} finding{?s}"
        )
      }
    }
  }

  cli::cli_text("")
  if (is.na(x$overall_score)) {
    cli::cli_alert_info("Overall usability score: not available")
  } else {
    cli::cli_alert_info(
      "Overall usability score: {round(x$overall_score * 100, 1)}%"
    )
  }
  invisible(x)
}
