test_that("usability_config_default returns a list", {
  cfg <- usability_config_default()
  expect_type(cfg, "list")
})

test_that("usability_config_default has required fields", {
  cfg <- usability_config_default()
  expect_true(all(c("label_min_chars", "label_max_chars",
                    "required_origins", "reviewer_guide_keywords",
                    "weights") %in% names(cfg)))
})

test_that("usability_config_default weights sum to 1", {
  cfg <- usability_config_default()
  expect_equal(sum(unlist(cfg$weights)), 1, tolerance = 1e-6)
})

test_that("usability_config_default label bounds are sensible", {
  cfg <- usability_config_default()
  expect_gt(cfg$label_max_chars, cfg$label_min_chars)
})
