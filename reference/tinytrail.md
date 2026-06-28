# Register a script in the project trail

Call once near the top of every script. Creates or updates an entry in
`_tinytrail.yaml` and sets the script name so that
[`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md)
can associate outputs with it.

## Usage

``` r
tinytrail(
  description,
  data_source = NULL,
  pin_to_top = FALSE,
  record_runtime = TRUE,
  name = NULL
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

## Value

`name` (the script name), invisibly. Called for its side effect of
creating or updating the YAML trail file in the project root.

## Examples

``` r
# \donttest{
withr::with_tempdir({
  writeLines("Version: 1.0", "DESCRIPTION")
  withr::with_options(
    list(.tinytrail_registry_path = NULL, .tinytrail_current_script = NULL), {

    tinytrail(
      description    = "Clean and reshape survey data",
      data_source    = "Current Population Survey (BLS)",
      record_runtime = FALSE,
      name           = "clean.R"
    )

    tinytrail(
      description    = "Sources and runs all project scripts in order",
      pin_to_top     = TRUE,
      record_runtime = FALSE,
      name           = "main.R"
    )
  })
})
# }
```
