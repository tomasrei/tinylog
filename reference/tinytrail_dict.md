# Add a data frame to the project data dictionary

Place at the end of a read/clean pipeline to capture column names and
optionally sample values. Returns the data frame unchanged.

## Usage

``` r
tinytrail_dict(
  df,
  .name = NULL,
  sample_values = TRUE,
  sample_string_length = 18L
)
```

## Arguments

- df:

  A data frame.

- .name:

  Character. Label for this entry. Defaults to the variable name of `df`
  as written in the calling code (e.g. `mtcars |> tinytrail_dict()`
  records as `"mtcars"`). Override when the expression is not a simple
  name or when you need a custom label.

- sample_values:

  Logical. Record 5 sample values per column. Default `TRUE`.

- sample_string_length:

  Integer or `Inf`. Maximum characters per sample value before
  truncating with `"..."`. Default `18L`.

## Value

`df`, invisibly.

## Details

Requires
[`tinytrail()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail.md)
to have been called first in the same session.

## Examples

``` r
# \donttest{
withr::with_tempdir({
  writeLines("Version: 1.0", "DESCRIPTION")
  withr::with_options(
    list(.tinytrail_registry_path = NULL, .tinytrail_current_script = NULL), {

    tinytrail("Analyse mtcars", name = "analysis.R", record_runtime = FALSE)
    dat <- mtcars |> tinytrail_dict(.name = "cars")
  })
})
# }
```
