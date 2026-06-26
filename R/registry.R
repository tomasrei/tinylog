# Walk up from getwd() to find the project root (looks for .Rproj, DESCRIPTION, .here, .git)
.find_root <- function() {
  path <- getwd()
  for (i in seq_len(20L)) {
    if (length(list.files(path, pattern = "\\.Rproj$")) > 0 ||
        file.exists(file.path(path, "DESCRIPTION")) ||
        file.exists(file.path(path, ".here")) ||
        file.exists(file.path(path, ".git"))) {
      return(path)
    }
    parent <- dirname(path)
    if (parent == path) break
    path <- parent
  }
  getwd()
}

`%||%` <- function(x, y) if (is.null(x)) y else x

.order_registry_entry <- function(entry) {
  key_order <- c("data_source", "description", "updated", "script_runtime", "n_plots", "n_tables", "outputs")
  entry[c(intersect(key_order, names(entry)), setdiff(names(entry), key_order))]
}

.get_current_script_name <- function() {
  idx <- which(vapply(sys.calls(), \(x) deparse(x[[1]]) == "source", logical(1)))
  if (length(idx) > 0) {
    frame <- sys.frame(idx[length(idx)])
    path <- if (is.character(frame$ofile)) frame$ofile else if (is.character(frame$file)) frame$file else NULL
    if (!is.null(path) && nzchar(path)) return(basename(path))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    path <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) NULL)
    if (is.character(path) && nzchar(path)) return(basename(path))
  }
  NULL
}

#' Register a script in the project registry
#'
#' Call once near the top of every script, after sourcing this package.
#' Creates or updates an entry in `_registry.yaml` and sets the script name
#' so that [record_output()] can associate outputs with it.
#'
#' @param data_source Character. The input data this script reads (path or description).
#' @param description Character. One-line description of what the script does.
#' @param name Character. Script name. Detected automatically when run via `source()`.
#' @param pin_to_top Logical. Pin this script to the top of the registry. Default `FALSE`.
#' @param record_runtime Logical. Record elapsed time on exit. Default `TRUE`.
#'
#' @export
register_script <- function(data_source,
                             description,
                             name = .get_current_script_name(),
                             pin_to_top = FALSE,
                             record_runtime = TRUE) {
  if (is.null(name)) {
    message("register_script: could not detect script name; run via source() or pass name= explicitly")
    return(invisible(NULL))
  }

  registry_path <- file.path(.find_root(), "_registry.yaml")

  if (file.exists(registry_path)) {
    registry <- yaml::read_yaml(registry_path)
  } else {
    registry <- list(
      `$version`    = "0.1.0",
      `$learn_more` = "https://data-dict.tidyverse.org",
      scripts       = list()
    )
  }

  entry <- list(
    data_source = data_source,
    description = description,
    updated     = format(Sys.time(), "%Y-%m-%d %H:%M"),
    outputs     = "none"
  )
  if (pin_to_top) entry$pin_to_top <- TRUE
  registry$scripts[[name]] <- entry

  all_names <- names(registry$scripts)
  pinned    <- all_names[vapply(registry$scripts[all_names], \(s) isTRUE(s$pin_to_top), logical(1))]
  rest      <- sort(all_names[!all_names %in% pinned])
  registry$scripts <- lapply(registry$scripts[c(pinned, rest)], .order_registry_entry)
  yaml::write_yaml(registry, registry_path)

  options(.tinylog_current_script = name)

  if (record_runtime) {
    .start    <- Sys.time()
    .name     <- name
    .reg_path <- registry_path
    idx <- which(vapply(sys.calls(), \(x) deparse(x[[1]]) == "source", logical(1)))
    if (length(idx) > 0) {
      eval(bquote(on.exit({
        .elapsed <- round(as.numeric(difftime(Sys.time(), .(.start), units = "mins")), 1)
        if (file.exists(.(.reg_path))) {
          .reg <- yaml::read_yaml(.(.reg_path))
          if (!is.null(.reg$scripts[[.(.name)]])) {
            .reg$scripts[[.(.name)]]$script_runtime <- paste0(.elapsed, " min")
            .reg$scripts <- lapply(.reg$scripts, .order_registry_entry)
            yaml::write_yaml(.reg, .(.reg_path))
            message(.(.name), ": ", .elapsed, " min elapsed")
          }
        }
      }, add = TRUE, after = TRUE)), envir = sys.frame(idx[length(idx)]))
    }
  }

  invisible(name)
}

#' Record an output file path in the registry
#'
#' Wraps the file path argument of any save call. Registers the path under the
#' current script's registry entry and returns the path unchanged, so it can be
#' dropped inline into any save function.
#'
#' Requires [register_script()] to have been called first in the same session.
#'
#' @param file Character. Absolute path to the output file.
#'
#' @return `file`, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' ggsave(filename = record_output(here::here("typst/plots/my_plot.png")))
#' write.csv(tab, file = record_output(here::here("data/misc/summary.csv")))
#' }
record_output <- function(file) {
  registry_path <- file.path(.find_root(), "_registry.yaml")
  script_name   <- getOption(".tinylog_current_script")

  if (is.null(script_name)) stop(
    "record_output() requires register_script() to have been called first."
  )
  if (!file.exists(registry_path)) return(invisible(file))

  root     <- .find_root()
  rel_file <- if (startsWith(file, root)) substring(file, nchar(root) + 2L) else file

  registry     <- yaml::read_yaml(registry_path)
  existing_raw <- registry$scripts[[script_name]]$outputs %||% list()
  existing <- if (identical(existing_raw, "none") || length(existing_raw) == 0) {
    character(0)
  } else {
    as.character(unlist(existing_raw))
  }

  all_out <- unique(c(existing, rel_file))
  outputs <- all_out[order(dirname(all_out),
                           startsWith(basename(all_out), "sensitivity_"),
                           basename(all_out))]

  registry$scripts[[script_name]]$outputs  <- outputs
  registry$scripts[[script_name]]$n_plots  <- sum(grepl("\\.png$", outputs))
  registry$scripts[[script_name]]$n_tables <- sum(grepl("\\.tex$", outputs))
  registry$scripts <- lapply(registry$scripts, .order_registry_entry)
  yaml::write_yaml(registry, registry_path)

  invisible(file)
}
