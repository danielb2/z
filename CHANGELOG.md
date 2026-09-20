# Changelog

## 2026-09-20

- Invalid options now fail with an error instead of continuing as a search.
- Searches with several terms no longer trigger Fish `test` errors before searching.
- Deleting a directory removes only that exact directory, including names containing regular-expression characters.
- Directory names containing pipes, newlines, backslashes, Unicode, or similar characters remain searchable after they are recorded.
- Cleanup and updates keep the data file private and preserve its configured owner.
- Failed data-file creation, cleanup, purge, or replacement now reports an error instead of appearing successful.
- Completion and manual-page entries now include directory opening and purge behavior.
- The README now documents both installation methods, common commands, and the current manual.

For maintainers:

- CI now installs the local plugin before running the integration tests.
- Regression tests cover special paths, invalid input, search modes, cleanup, deletion, and file permissions.

## 2025.12.17

- Allowed `$Z_CMD` to be set to `cd`.

## 2025.12.16

- Implemented `..`, `-`, and empty-command behavior to match `cd`.
- Changed local-directory handling to use an existing local directory instead of jumping.
