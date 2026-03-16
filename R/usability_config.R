#' Default Usability Assessment Configuration
#'
#' Returns the default configuration list used by [usability_indicators()] and
#' individual assessment functions.
#'
#' @return A named list with the following elements:
#'   \describe{
#'     \item{label_min_chars}{Minimum recommended label length (integer).}
#'     \item{label_max_chars}{Maximum recommended label length (integer).}
#'     \item{required_origins}{Character vector of origins that require a
#'       derivation text (e.g. `"Derived"`, `"Assigned"`).}
#'     \item{reviewer_guide_keywords}{Character vector of asset names that
#'       count as reviewer guide presence.}
#'     \item{weights}{Named list of relative indicator weights summing to 1:
#'       `label_quality`, `define_completeness`, `annotation_coverage`,
#'       `reviewer_guide`.}
#'   }
#'
#' @examples
#' cfg <- usability_config_default()
#' cfg$label_min_chars
#' cfg$weights$label_quality
#'
#' @export
usability_config_default <- function() {
  list(
    label_min_chars        = 3L,
    label_max_chars        = 40L,
    required_origins       = c("Derived", "Assigned"),
    reviewer_guide_keywords = c("ADRG", "SDRG", "reviewers_guide",
                                "reviewer_guide", "ARG"),
    weights = list(
      label_quality        = 0.30,
      define_completeness  = 0.35,
      annotation_coverage  = 0.25,
      reviewer_guide       = 0.10
    )
  )
}
