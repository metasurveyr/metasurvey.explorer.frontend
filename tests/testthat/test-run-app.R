# Ver RFC-MODULARIZACION.md · paquete metasurvey.explorer.frontend
# Migrado de metasurvey-legacy/tests/testthat/test-survey.R (bloque explore_recipes)

test_that("explore_recipes errors when shiny not available", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) pkg != "shiny",
    .package = "base"
  )
  expect_error(explore_recipes(), "shiny")
})

test_that("explore_recipes errors when bslib not available", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) pkg != "bslib",
    .package = "base"
  )
  expect_error(explore_recipes(), "bslib")
})

test_that("explore_recipes calls runApp with correct args", {
  skip_if_not_installed("shiny")
  called_with <- list()
  local_mocked_bindings(
    runApp = function(appDir, port = NULL, host = "127.0.0.1",
                      launch.browser = TRUE, ...) {
      called_with$appDir <<- appDir
      called_with$port <<- port
      called_with$host <<- host
      called_with$launch.browser <<- launch.browser
      invisible(NULL)
    },
    .package = "shiny"
  )
  explore_recipes(port = 4321, host = "0.0.0.0", launch.browser = FALSE)
  expect_true(nzchar(called_with$appDir))
  expect_equal(called_with$port, 4321)
  expect_equal(called_with$host, "0.0.0.0")
  expect_false(called_with$launch.browser)
})
