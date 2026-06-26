test_that("record_output() errors without register_script()", {
  options(.tinylog_current_script = NULL)
  expect_error(record_output("some/file.png"), "register_script")
})

test_that("register_script() sets the script name option", {
  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)
  withr::local_options(.tinylog_current_script = NULL)

  register_script(
    name        = "test.R",
    data_source = "none",
    description = "test",
    record_runtime = FALSE
  )

  expect_equal(getOption(".tinylog_current_script"), "test.R")
  expect_true(file.exists("_registry.yaml"))
})

test_that("record_output() registers path and returns it", {
  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)
  withr::local_options(.tinylog_current_script = NULL)

  register_script(
    name        = "test.R",
    data_source = "none",
    description = "test",
    record_runtime = FALSE
  )

  path <- file.path(tmp, "output.png")
  result <- record_output(path)

  expect_equal(result, path)

  reg <- yaml::read_yaml("_registry.yaml")
  expect_true(any(grepl("output.png", unlist(reg$scripts[["test.R"]]$outputs))))
})
