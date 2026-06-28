# Getting started with tinytrail

``` r

library(tinytrail)
```

`tinytrail` is a package that — once initialized — leaves a ‘tiny trail’
of human- and AI-readable log-entries in a `yaml` that makes it
effortless to keep track of small to medium-sized projects. The package
is lightweight (hence ‘tiny’) and maintains a YAML trail file recording
which scripts produced which output files.

## The two core functions

Place two calls in every script and the trail stays current
automatically.

| Function | Where to use it |
|----|----|
| [`tinytrail()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail.md) | Once, near the top of every script |
| [`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md) | Inline around any file path you save to |

Call
[`tinytrail()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail.md)
once at the top of each script with a short description of what the
script does:

``` r

library(tinytrail)

# --- top of 01_clean.R ---
tinytrail(
  description = "Clean and reshape survey data",
  data_source = "Current Population Survey (BLS)"
)
```

Then wrap the file path argument of any save call with
[`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md).
It logs the path and returns it unchanged, so it slots directly into the
`file =` argument of any write function:

``` r

write.csv(
  survey,
  file = tinytrail_write("data/clean/survey_clean.csv")
)
```

It works equally well with `here::here()`:

``` r

write.csv(
  survey,
  file = tinytrail_write(here::here("data/clean/survey_clean.csv"))
)
```

That is all you need to add. The trail file (`_tinytrail.yaml`) is
created in the project root on the first run and updated on every
subsequent run:

``` yaml
$version: 0.1.0
$learn_more: https://github.com/tinytrail-r/tinytrail
scripts:
  01_clean.R:
    description: Clean and reshape survey data
    data_source: Current Population Survey (BLS)
    first_run: '2026-01-15 09:12'
    latest_run: '2026-01-20 11:05'
    script_runtime: 0.3 min
    n_outputs: 1
    outputs:
    - data/clean/survey_clean.csv
  02_model.R:
    description: Fit logistic regression
    data_source: Cleaned survey data (01_clean.R)
    first_run: '2026-01-16 14:22'
    latest_run: '2026-01-20 11:08'
    script_runtime: 1.4 min
    n_outputs: 2
    outputs:
    - results/model_fit.rds
    - results/table_coefficients.csv
```

## Adding a data dictionary

[`tinytrail_dict()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_dict.md)
is an optional third function. Place it at the end of a read or clean
pipeline to capture column names and sample values for each input data
frame:

``` r

survey <- read.csv("data/raw/survey.csv") |>
  tinytrail_dict()
```

The entry is stored under the calling script in the trail file:

``` yaml
data_dictionary:
  01_clean.R:
    survey:
      columns:
        id: [1, 2, 3, 4, 5]
        age: [34, 52, 28, 41, 37]
        response: ['yes', 'no', 'yes', 'yes', 'no']
```

To omit sample values and record only column names, use
`sample_values = FALSE`:

``` r

survey <- read.csv("data/raw/survey.csv") |>
  tinytrail_dict(sample_values = FALSE)
```

## Options

Pin an important script to the top of the trail — useful for a `main.R`
that sources other scripts:

``` r

tinytrail(
  description = "Master data preparation",
  data_source = "Admin registry (Statistics Sweden)",
  pin_to_top  = TRUE
)
```
