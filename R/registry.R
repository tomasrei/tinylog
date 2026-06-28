# Registry: project root detection, YAML read/write, and entry management

.has_root_marker <- function(path) {
  length(list.files(path, pattern = "\\.Rproj$")) > 0 ||
    file.exists(file.path(path, "DESCRIPTION"))       ||
    file.exists(file.path(path, ".here"))             ||
    file.exists(file.path(path, ".git"))
}

.find_root <- function() {
  starts <- unique(c(getwd(), .script_dir()))
  for (start in starts) {
    path <- start
    for (i in seq_len(.ROOT_SEARCH_DEPTH)) {
      if (.has_root_marker(path)) return(path)
      parent <- dirname(path)
      if (parent == path) break
      path <- parent
    }
  }
  .script_dir() %||% getwd()
}

.registry_path <- function() {
  getOption(".tinytrail_registry_path") %||%
    file.path(.find_root(), .REGISTRY_FILENAME)
}

.read_or_init_registry <- function(path) {
  if (file.exists(path)) return(yaml::read_yaml(path))
  list(
    `$version`    = .TINYTRAIL_VERSION,
    `$learn_more` = .TINYTRAIL_URL,
    scripts       = list()
  )
}

.order_registry_entry <- function(entry) {
  entry[c(intersect(.KEY_ORDER, names(entry)), setdiff(names(entry), .KEY_ORDER))]
}

.yaml_scalar <- function(v) {
  if (is.null(v) || (length(v) == 1L && is.na(v))) return("null")
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  if (is.numeric(v)) return(as.character(v))
  paste0("'", gsub("'", "''", as.character(v)), "'")
}

.truncate_sample_value <- function(v, max_chars) {
  if (!(is.character(v) || is.factor(v))) return(v)
  s <- as.character(v)
  if (is.finite(max_chars) && nchar(s) > max_chars)
    paste0(substr(s, 1L, max_chars), "...")
  else s
}

.format_dd_yaml <- function(dict) {
  lines <- "data_dictionary:"
  for (script in names(dict)) {
    lines <- c(lines, paste0("  ", script, ":"))
    for (input_name in names(dict[[script]])) {
      lines <- c(lines, paste0("    ", input_name, ":"))
      cols <- dict[[script]][[input_name]]$columns
      if (!is.null(names(cols))) {
        # sample_values = TRUE: named list -- one inline sequence per column
        lines <- c(lines, "      columns:")
        for (col_name in names(cols)) {
          vals <- vapply(cols[[col_name]], .yaml_scalar, character(1L))
          lines <- c(lines, paste0("        ", .yaml_scalar(col_name), ": [", paste(vals, collapse = ", "), "]"))
        }
      } else {
        # sample_values = FALSE: flat list of column names, also inline
        col_scalars <- vapply(unlist(cols), .yaml_scalar, character(1L))
        lines <- c(lines, paste0("      columns: [", paste(col_scalars, collapse = ", "), "]"))
      }
    }
  }
  paste(lines, collapse = "\n")
}

.write_registry <- function(registry, path) {
  dict <- registry$data_dictionary
  main <- registry[names(registry) != "data_dictionary"]
  main_yaml <- yaml::as.yaml(main)
  if (is.null(dict) || length(dict) == 0L) {
    cat(main_yaml, file = path)
  } else {
    cat(main_yaml, .format_dd_yaml(dict), "\n", sep = "", file = path)
  }
  invisible(NULL)
}

.warn_no_tinytrail <- function(script_name, registry_path) {
  registry <- .read_or_init_registry(registry_path)
  registry$scripts[[script_name]] <- list(
    warning = paste0(
      "Did you forget to add tinytrail() at the top of '", script_name, "'? ",
      "Outputs and data dictionary entries will not be recorded until tinytrail() is called."
    )
  )
  .write_registry(registry, registry_path)
  if (!isTRUE(getOption(".tinytrail_warned"))) {
    message("tinytrail: warning written to ", registry_path)
    options(.tinytrail_warned = TRUE)
  }
}
