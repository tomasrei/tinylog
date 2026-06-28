# Record an output file path in the trail

Wraps the file path argument of any save call. Registers the path under
the current script's trail entry and returns the path unchanged, so it
can be dropped inline into any save function.

## Usage

``` r
tinytrail_write(file)
```

## Arguments

- file:

  Character. Path to the output file.

## Value

`file`, invisibly.

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

    tinytrail("Process raw data", name = "analysis.R", record_runtime = FALSE)
    out <- tinytrail_write("output/results.csv")
  })
})
# }
```
