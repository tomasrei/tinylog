# Changelog

## tinytrail 0.1.0

- Initial release (renamed from `tinylog`).
- [`tinytrail()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail.md)
  registers a script in the project YAML trail and optionally records
  elapsed runtime.
- [`tinytrail_write()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_write.md)
  wraps any save call to log the output file path under the calling
  script’s trail entry.
- [`tinytrail_dict()`](https://tinytrail-r.github.io/tinytrail/reference/tinytrail_dict.md)
  captures column names and sample values for input data frames.
