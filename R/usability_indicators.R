#' Assess Variable Label Quality
#'
#' Evaluates the quality of variable labels in a metadata data frame. Each
#' variable is checked for label presence, length within the recommended range,
#' and absence of prohibited characters. Results are returned as R4SUB evidence
#' rows with `indicator_id = "U-001"`.
#'
#' @param metadata A data frame with at least columns `dataset` (character),
#'   `variable` (character), and `label` (character).
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#'
#' @return A validated evidence tibble (see [r4subcore::as_evidence()]).
#'
#' @examples
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' meta <- data.frame(
#'   dataset  = c("ADSL", "ADSL", "ADAE"),
#'   variable = c("USUBJID", "AGE", "AETERM"),
#'   label    = c("Unique Subject Identifier", "Age", ""),
#'   stringsAsFactors = FALSE
#' )
#' ev <- assess_label_quality(meta, ctx)
#' nrow(ev)
#'
#' @export
assess_label_quality <- function(metadata, ctx, config = NULL) {
  if (is.null(config)) config <- usability_config_default()
  metadata  <- as.data.frame(metadata)

  required_cols <- c("dataset", "variable", "label")
  missing <- setdiff(required_cols, names(metadata))
  if (length(missing) > 0L) {
    cli::cli_abort("metadata is missing columns: {.field {missing}}")
  }

  rows <- lapply(seq_len(nrow(metadata)), function(i) {
    ds  <- metadata$dataset[i]
    var <- metadata$variable[i]
    lbl <- metadata$label[i]

    lbl_clean <- trimws(as.character(lbl))
    n_char    <- nchar(lbl_clean)

    if (is.na(lbl) || nchar(lbl_clean) == 0L) {
      result <- "fail"; severity <- "high"
      msg    <- paste0(var, ": label is empty")
      metric <- 0
    } else if (n_char < config$label_min_chars) {
      result <- "warn"; severity <- "medium"
      msg    <- paste0(var, ": label too short (", n_char, " chars)")
      metric <- 0.5
    } else if (n_char > config$label_max_chars) {
      result <- "warn"; severity <- "low"
      msg    <- paste0(var, ": label too long (", n_char, " chars)")
      metric <- 0.75
    } else {
      result <- "pass"; severity <- "info"
      msg    <- paste0(var, ": label OK")
      metric <- 1
    }

    data.frame(
      asset_type       = "spec",
      asset_id         = ds,
      source_name      = "r4subusability",
      source_version   = as.character(utils::packageVersion("r4subusability")),
      indicator_id     = "U-001",
      indicator_name   = "Variable Label Quality",
      indicator_domain = "usability",
      severity         = severity,
      result           = result,
      metric_value     = metric,
      metric_unit      = "score",
      message          = msg,
      location         = paste0(ds, ".", var),
      evidence_payload = "{}",
      stringsAsFactors = FALSE
    )
  })

  ev <- do.call(rbind, rows)
  r4subcore::as_evidence(ev, ctx = ctx)
}

#' Assess Define-XML Completeness
#'
#' Evaluates whether all datasets and variables in the metadata have the
#' required Define-XML fields populated (label, origin, derivation for derived
#' variables, and codelist reference where applicable). Results are returned as
#' R4SUB evidence rows with `indicator_id = "U-002"`.
#'
#' @param metadata A data frame with columns `dataset`, `variable`, `label`,
#'   `origin` (character), `derivation` (character, may be `NA`), and
#'   `codelist` (character, may be `NA`).
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#'
#' @return A validated evidence tibble (see [r4subcore::as_evidence()]).
#'
#' @examples
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' meta <- data.frame(
#'   dataset    = c("ADSL", "ADSL"),
#'   variable   = c("USUBJID", "AGE"),
#'   label      = c("Unique Subject Identifier", "Age"),
#'   origin     = c("CRF", "Derived"),
#'   derivation = c(NA, "Derived from BRTHDTC"),
#'   codelist   = c(NA, NA),
#'   stringsAsFactors = FALSE
#' )
#' ev <- assess_define_completeness(meta, ctx)
#' nrow(ev)
#'
#' @export
assess_define_completeness <- function(metadata, ctx, config = NULL) {
  if (is.null(config)) config <- usability_config_default()
  metadata <- as.data.frame(metadata)

  required_cols <- c("dataset", "variable", "label", "origin")
  missing <- setdiff(required_cols, names(metadata))
  if (length(missing) > 0L) {
    cli::cli_abort("metadata is missing columns: {.field {missing}}")
  }

  if (!"derivation" %in% names(metadata)) metadata$derivation <- NA_character_
  if (!"codelist"   %in% names(metadata)) metadata$codelist   <- NA_character_

  rows <- lapply(seq_len(nrow(metadata)), function(i) {
    ds     <- metadata$dataset[i]
    var    <- metadata$variable[i]
    origin <- trimws(as.character(metadata$origin[i]))
    deriv  <- metadata$derivation[i]

    needs_derivation <- origin %in% config$required_origins
    has_derivation   <- !is.na(deriv) && nchar(trimws(as.character(deriv))) > 0L

    if (is.na(origin) || nchar(origin) == 0L) {
      result <- "fail"; severity <- "high"; metric <- 0
      msg    <- paste0(var, ": origin not specified")
    } else if (needs_derivation && !has_derivation) {
      result <- "fail"; severity <- "high"; metric <- 0
      msg    <- paste0(var, ": derivation missing for origin '", origin, "'")
    } else if (needs_derivation && has_derivation) {
      result <- "pass"; severity <- "info"; metric <- 1
      msg    <- paste0(var, ": derivation documented")
    } else {
      result <- "pass"; severity <- "info"; metric <- 1
      msg    <- paste0(var, ": origin '", origin, "' documented")
    }

    data.frame(
      asset_type       = "define",
      asset_id         = ds,
      source_name      = "r4subusability",
      source_version   = as.character(utils::packageVersion("r4subusability")),
      indicator_id     = "U-002",
      indicator_name   = "Define-XML Completeness",
      indicator_domain = "usability",
      severity         = severity,
      result           = result,
      metric_value     = metric,
      metric_unit      = "score",
      message          = msg,
      location         = paste0(ds, ".", var),
      evidence_payload = "{}",
      stringsAsFactors = FALSE
    )
  })

  ev <- do.call(rbind, rows)
  r4subcore::as_evidence(ev, ctx = ctx)
}

#' Assess Dataset Annotation Coverage
#'
#' Checks what proportion of derived variables have derivation text documented.
#' Returns one evidence row per dataset summarising annotation coverage, with
#' `indicator_id = "U-003"`.
#'
#' @param metadata A data frame with columns `dataset`, `variable`, `origin`,
#'   and `derivation`.
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#'
#' @return A validated evidence tibble (see [r4subcore::as_evidence()]).
#'
#' @examples
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' meta <- data.frame(
#'   dataset    = c("ADSL", "ADSL", "ADSL"),
#'   variable   = c("AGE", "SEX", "RACE"),
#'   origin     = c("Derived", "CRF", "Derived"),
#'   derivation = c("Derived from BRTHDTC", NA, NA),
#'   stringsAsFactors = FALSE
#' )
#' ev <- assess_annotation_coverage(meta, ctx)
#' ev$metric_value
#'
#' @export
assess_annotation_coverage <- function(metadata, ctx, config = NULL) {
  if (is.null(config)) config <- usability_config_default()
  metadata <- as.data.frame(metadata)

  if (!"derivation" %in% names(metadata)) metadata$derivation <- NA_character_

  datasets <- unique(metadata$dataset)

  rows <- lapply(datasets, function(ds) {
    sub    <- metadata[metadata$dataset == ds, ]
    derived <- sub[sub$origin %in% config$required_origins, ]
    n_derived <- nrow(derived)

    if (n_derived == 0L) {
      result <- "na"; severity <- "info"; metric <- 1
      msg    <- paste0(ds, ": no derived variables")
    } else {
      n_documented <- sum(
        !is.na(derived$derivation) &
          nchar(trimws(as.character(derived$derivation))) > 0L
      )
      metric <- n_documented / n_derived

      if (metric >= 0.9) {
        result <- "pass"; severity <- "info"
      } else if (metric >= 0.7) {
        result <- "warn"; severity <- "medium"
      } else {
        result <- "fail"; severity <- "high"
      }
      msg <- sprintf("%s: %.0f%% of derived variables annotated (%d/%d)",
                     ds, metric * 100, n_documented, n_derived)
    }

    data.frame(
      asset_type       = "spec",
      asset_id         = ds,
      source_name      = "r4subusability",
      source_version   = as.character(utils::packageVersion("r4subusability")),
      indicator_id     = "U-003",
      indicator_name   = "Annotation Coverage",
      indicator_domain = "usability",
      severity         = severity,
      result           = result,
      metric_value     = metric,
      metric_unit      = "proportion",
      message          = msg,
      location         = ds,
      evidence_payload = "{}",
      stringsAsFactors = FALSE
    )
  })

  ev <- do.call(rbind, rows)
  r4subcore::as_evidence(ev, ctx = ctx)
}

#' Assess Reviewer Guide Presence
#'
#' Checks whether a reviewer guide document (Analysis Data Reviewer's Guide or
#' Study Data Reviewer's Guide) is declared in the submission asset list.
#' Returns evidence rows with `indicator_id = "U-004"`.
#'
#' @param assets A character vector of asset names or file names present in the
#'   submission package (e.g. `c("ADRG", "define.xml", "datasets")`).
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#'
#' @return A validated evidence tibble with one row (see
#'   [r4subcore::as_evidence()]).
#'
#' @examples
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' ev_present <- assess_reviewer_guide(c("ADRG", "define.xml"), ctx)
#' ev_missing <- assess_reviewer_guide(c("define.xml"), ctx)
#' ev_present$result
#' ev_missing$result
#'
#' @export
assess_reviewer_guide <- function(assets, ctx, config = NULL) {
  if (is.null(config)) config <- usability_config_default()

  assets_lower   <- tolower(assets)
  keywords_lower <- tolower(config$reviewer_guide_keywords)
  found          <- any(sapply(keywords_lower, function(k) any(grepl(k, assets_lower))))

  if (found) {
    result <- "pass"; severity <- "info"; metric <- 1
    msg    <- "Reviewer guide asset detected in submission package"
  } else {
    result <- "fail"; severity <- "high"; metric <- 0
    msg    <- "No reviewer guide (ADRG/SDRG) detected in submission package"
  }

  ev <- data.frame(
    asset_type       = "spec",
    asset_id         = "submission_package",
    source_name      = "r4subusability",
    source_version   = as.character(utils::packageVersion("r4subusability")),
    indicator_id     = "U-004",
    indicator_name   = "Reviewer Guide Presence",
    indicator_domain = "usability",
    severity         = severity,
    result           = result,
    metric_value     = metric,
    metric_unit      = "score",
    message          = msg,
    location         = "submission_package",
    evidence_payload = "{}",
    stringsAsFactors = FALSE
  )

  r4subcore::as_evidence(ev, ctx = ctx)
}

#' Assess All Usability Indicators
#'
#' Convenience wrapper that runs all four usability assessments and returns a
#' combined evidence table. This is the primary entry point for the
#' `r4subusability` package.
#'
#' @param metadata A data frame with columns `dataset`, `variable`, `label`,
#'   `origin`, `derivation` (optional), and `codelist` (optional). Compatible
#'   with the `adam_metadata` and `sdtm_metadata` datasets from `r4subdata`.
#' @param assets A character vector of asset names present in the submission
#'   package. Used by [assess_reviewer_guide()]. Defaults to `character(0)`.
#' @param ctx A run context created by [r4subcore::r4sub_run_context()].
#' @param config A configuration list from [usability_config_default()]. If
#'   `NULL` the default configuration is used.
#'
#' @return A validated evidence tibble combining results from all four
#'   usability assessments (see [r4subcore::as_evidence()]).
#'
#' @examples
#' \donttest{
#' ctx <- r4subcore::r4sub_run_context(study_id = "STUDY01")
#' meta <- data.frame(
#'   dataset    = c("ADSL", "ADSL", "ADAE"),
#'   variable   = c("USUBJID", "AGE", "AETERM"),
#'   label      = c("Unique Subject Identifier", "Age", "Adverse Event Term"),
#'   origin     = c("CRF", "Derived", "CRF"),
#'   derivation = c(NA, "Derived from BRTHDTC and RFSTDTC", NA),
#'   stringsAsFactors = FALSE
#' )
#' assets <- c("ADRG", "define.xml")
#' ev <- usability_indicators(meta, assets = assets, ctx = ctx)
#' nrow(ev)
#' table(ev$result)
#' }
#'
#' @export
usability_indicators <- function(metadata, assets = character(0), ctx, config = NULL) {
  if (is.null(config)) config <- usability_config_default()

  ev_label  <- assess_label_quality(metadata, ctx = ctx, config = config)
  ev_define <- assess_define_completeness(metadata, ctx = ctx, config = config)
  ev_annot  <- assess_annotation_coverage(metadata, ctx = ctx, config = config)
  ev_guide  <- assess_reviewer_guide(assets, ctx = ctx, config = config)

  r4subcore::bind_evidence(ev_label, ev_define, ev_annot, ev_guide)
}
