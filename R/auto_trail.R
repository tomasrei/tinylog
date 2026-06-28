# Public API: tinytrail_auto()
#
# Sub-functions used exclusively by the public API are defined first.

# Built-in write functions to intercept: key -> list(fn, pkg, arg)
# "arg" is the parameter name holding the output file path in each function.
.WRITE_HOOKS <- list(
  write.table   = list(fn = "write.table",   pkg = "utils",      arg = "file"),
  write.csv     = list(fn = "write.csv",     pkg = "utils",      arg = "file"),
  write.csv2    = list(fn = "write.csv2",    pkg = "utils",      arg = "file"),
  saveRDS       = list(fn = "saveRDS",       pkg = "base",       arg = "file"),
  save          = list(fn = "save",          pkg = "base",       arg = "file"),
  write_csv     = list(fn = "write_csv",     pkg = "readr",      arg = "file"),
  write_tsv     = list(fn = "write_tsv",     pkg = "readr",      arg = "file"),
  write_delim   = list(fn = "write_delim",   pkg = "readr",      arg = "file"),
  write_rds     = list(fn = "write_rds",     pkg = "readr",      arg = "file"),
  ggsave        = list(fn = "ggsave",        pkg = "ggplot2",    arg = "filename"),
  write_xlsx    = list(fn = "write_xlsx",    pkg = "writexl",    arg = "path"),
  saveWorkbook  = list(fn = "saveWorkbook",  pkg = "openxlsx",   arg = "file"),
  write_parquet = list(fn = "write_parquet", pkg = "arrow",      arg = "sink"),
  write_feather = list(fn = "write_feather", pkg = "arrow",      arg = "sink"),
  write_sav     = list(fn = "write_sav",     pkg = "haven",      arg = "path"),
  write_dta     = list(fn = "write_dta",     pkg = "haven",      arg = "path"),
  write_sas     = list(fn = "write_sas",     pkg = "haven",      arg = "path"),
  write_json    = list(fn = "write_json",    pkg = "jsonlite",   arg = "path"),
  fwrite        = list(fn = "fwrite",        pkg = "data.table", arg = "file")
)

# Parses "pkg::fn" or "fn" from an extra_hooks entry into a spec list.
.parse_hook_spec <- function(entry_name, arg) {
  if (grepl("::", entry_name, fixed = TRUE)) {
    parts <- strsplit(entry_name, "::", fixed = TRUE)[[1L]]
    list(fn = parts[2L], pkg = parts[1L], arg = arg)
  } else {
    list(fn = entry_name, pkg = NULL, arg = arg)
  }
}

# Traces a single function. Returns TRUE on success, FALSE if unavailable.
.hook_one <- function(fn_name, pkg, arg) {
  ns <- if (!is.null(pkg)) {
    if (!requireNamespace(pkg, quietly = TRUE)) return(FALSE)
    asNamespace(pkg)
  } else {
    globalenv()
  }

  tracer <- bquote(
    tryCatch({
      if (!is.null(getOption(".tinytrail_current_script"))) {
        val <- .(as.name(arg))
        if (is.character(val) && length(val) == 1L && nzchar(val))
          tinytrail_write(val)
      }
    }, error = function(e) NULL)
  )

  tryCatch(
    { suppressMessages(trace(fn_name, tracer = tracer, print = FALSE, where = ns)); TRUE },
    error = function(e) FALSE
  )
}

# Activates hooks for all built-in write functions plus any user-supplied extras.
# Stores the active key list and full hook table in options for teardown.
.setup_write_hooks <- function(extra = NULL) {
  hooks <- .WRITE_HOOKS
  if (!is.null(extra)) {
    parsed <- Map(.parse_hook_spec, names(extra), extra)
    for (spec in parsed)
      hooks[[paste0(spec$pkg %||% "global", "::", spec$fn)]] <- spec
  }

  traced <- character(0)
  for (key in names(hooks)) {
    spec <- hooks[[key]]
    if (.hook_one(spec$fn, spec$pkg, spec$arg)) traced <- c(traced, key)
  }

  options(.tinytrail_traced_fns  = traced,
          .tinytrail_hooks_table = hooks)
  invisible(traced)
}

# Removes all active hooks and clears the tracking options.
.teardown_write_hooks <- function() {
  traced <- getOption(".tinytrail_traced_fns",  character(0))
  hooks  <- getOption(".tinytrail_hooks_table", list())
  for (key in traced) {
    spec <- hooks[[key]]
    if (is.null(spec)) next
    ns <- if (!is.null(spec$pkg)) {
      tryCatch(asNamespace(spec$pkg), error = function(e) NULL)
    } else {
      globalenv()
    }
    if (!is.null(ns))
      tryCatch(suppressMessages(untrace(spec$fn, where = ns)), error = function(e) NULL)
  }
  options(.tinytrail_traced_fns  = NULL,
          .tinytrail_hooks_table = NULL)
  invisible(NULL)
}

#' Register a script and automatically track all write/save calls
#'
#' Drop-in alternative to `tinytrail()`. Call once near the top of every
#' script. In addition to registering the script in `_tinytrail.yaml`, it
#' hooks common write functions (`write.csv`, `saveRDS`, `readr::write_csv`,
#' `ggplot2::ggsave`, etc.) so their output file paths are recorded
#' automatically — no `tinytrail_write()` wrapper needed on each save call.
#' Hooks are silently removed when the script exits.
#'
#' @param description Character. Description of what the script does.
#' @param data_source Character. Optional. Enter the sources of data used in
#'   this script — name the dataset or survey, not a file path
#'   (e.g. `"Current Population Survey (BLS)"`).
#' @param pin_to_top Logical. Pin this script to the top of the trail. Useful
#'   for a `main.R` that sources other scripts — keeps it visible at the top of
#'   `_tinytrail.yaml` regardless of alphabetical order. Default `FALSE`.
#' @param record_runtime Logical. Record elapsed time on exit. Default `TRUE`.
#' @param name Character. Override the auto-detected script name. Useful in
#'   testing or when auto-detection is not available.
#' @param extra_hooks Named character vector of additional write functions to
#'   intercept. Names are function identifiers (`"fn"` for a function defined
#'   in the script, or `"pkg::fn"` for a package function), values are the
#'   name of the file-path argument in that function. Example:
#'   `c(my_save = "path", "sf::st_write" = "dsn")`. Functions from packages
#'   that are not installed are silently skipped.
#'
#' @returns `name` (the script name), invisibly. Called for its side effect of
#'   creating or updating the YAML trail file in the project root.
#' @export
#'
#' @examples
#' \donttest{
#' withr::with_tempdir({
#'   writeLines("Version: 1.0", "DESCRIPTION")
#'   withr::with_options(
#'     list(.tinytrail_registry_path = NULL, .tinytrail_current_script = NULL,
#'          .tinytrail_traced_fns = NULL, .tinytrail_hooks_table = NULL), {
#'
#'     tinytrail_auto(
#'       description    = "Clean and reshape survey data",
#'       data_source    = "Current Population Survey (BLS)",
#'       record_runtime = FALSE,
#'       name           = "clean.R"
#'     )
#'
#'     write.csv(mtcars, "cars.csv")   # recorded automatically
#'     saveRDS(mtcars,   "cars.rds")   # recorded automatically
#'   })
#' })
#' }
tinytrail_auto <- function(description,
                           data_source    = NULL,
                           pin_to_top     = FALSE,
                           record_runtime = TRUE,
                           name           = NULL,
                           extra_hooks    = NULL) {
  tinytrail(
    description    = description,
    data_source    = data_source,
    pin_to_top     = pin_to_top,
    record_runtime = record_runtime,
    name           = name
  )

  .setup_write_hooks(extra = extra_hooks)

  do.call(
    on.exit,
    list(quote(.teardown_write_hooks()), add = TRUE, after = TRUE),
    envir = parent.frame()
  )

  invisible(getOption(".tinytrail_current_script"))
}
