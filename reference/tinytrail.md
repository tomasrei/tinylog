# Register a script in the project trail

Call once near the top of every script. Creates or updates an entry in
`_tinytrail.yaml` and sets the script name so that outputs can be
recorded.

## Usage

``` r
tinytrail(
  description,
  data_source = NULL,
  pin_to_top = FALSE,
  record_runtime = TRUE,
  name = NULL,
  auto = TRUE,
  extra_hooks = NULL
)
```

## Arguments

- description:

  Character. Description of what the script does.

- data_source:

  Character. Optional. Enter the sources of data used in this script —
  name the dataset or survey, not a file path (e.g.
  `"Current Population Survey (BLS)"`).

- pin_to_top:

  Logical. Pin this script to the top of the trail. Useful for a
  `main.R` that sources other scripts — keeps it visible at the top of
  `_tinytrail.yaml` regardless of alphabetical order. Default `FALSE`.

- record_runtime:

  Logical. Record elapsed time on exit. Default `TRUE`.

- name:

  Character. Override the auto-detected script name. Useful in testing
  or when auto-detection is not available.

- auto:

  Logical. Automatically intercept common write functions and record
  their output paths. Default `TRUE`. Set to `FALSE` to use explicit
  [`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md)
  calls instead.

- extra_hooks:

  Named character vector of additional write functions to intercept when
  `auto = TRUE`. Names are function identifiers (`"fn"` for a function
  defined in the script, or `"pkg::fn"` for a package function), values
  are the name of the file-path argument in that function. Example:
  `c(my_save = "path", "sf::st_write" = "dsn")`. Functions from packages
  that are not installed are silently skipped.

## Value

`name` (the script name), invisibly. Called for its side effect of
creating or updating the YAML trail file in the project root.

## Details

By default (`auto = TRUE`) common write functions (`write.csv`,
`saveRDS`, `readr::write_csv`, `ggplot2::ggsave`, etc.) are hooked
automatically so their output file paths are captured without any
[`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md)
wrapper. Set `auto = FALSE` to use explicit
[`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md)
calls instead.

## Examples

``` r
# \donttest{
withr::with_tempdir({
  writeLines("Version: 1.0", "DESCRIPTION")
  withr::with_options(
    list(.tinytrail_registry_path = NULL, .tinytrail_current_script = NULL,
         .tinytrail_traced_fns = NULL, .tinytrail_hooks_table = NULL), {

    # auto = TRUE (default): write.csv captured without tinytrail_write()
    tinytrail(
      description    = "Clean and reshape survey data",
      data_source    = "Current Population Survey (BLS)",
      record_runtime = FALSE,
      name           = "clean.R"
    )
    write.csv(mtcars, "cars.csv")

    # auto = FALSE: use explicit tinytrail_write() wrappers
    tinytrail(
      description    = "Sources and runs all project scripts in order",
      pin_to_top     = TRUE,
      record_runtime = FALSE,
      auto           = FALSE,
      name           = "main.R"
    )
  })
})
#> Error in .teardown_write_hooks(): could not find function ".teardown_write_hooks"
# }
```
