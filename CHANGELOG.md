# Changelog

## 2026-09-21

- [fix] Cleanup removes missing directories without removing live entries.
- [fix] Cleanup preserves the database format while rewriting valid rows.
- [maintenance] Cleanup tests use synthetic stale records and do not delete directories.
- [feature] Added opt-in fuzzy matching with `--fuzzy` and `Z_FUZZY=true`.
- [feature] Added `-v/--version`, reporting the fork version `3.0.0`.
- [feature] Added `--increase` and `--decrease` to adjust the current directory's weight.
- [fix] Made list output sorting portable on BSD and GNU systems.
- [fix] List output now shows stored weight separately from frecency score.
- [maintenance] Require complete functional coverage for changed behavior and final-suite verification.

## 2026-09-20

- [fix] Invalid options now fail with an error instead of continuing as a search.
- [fix] Searches with several terms no longer trigger Fish `test` errors before searching.
- [fix] Deleting a directory removes only that exact directory, including names containing regular-expression characters.
- [fix] Directory names containing pipes, newlines, backslashes, Unicode, or similar characters remain searchable after they are recorded.
- [fix] Cleanup and updates keep the data file private and preserve its configured owner.
- [fix] Failed data-file creation, cleanup, purge, or replacement now reports an error instead of appearing successful.
- [fix] Repeated visits merge old and new storage records instead of creating duplicate entries.
- [fix] Equal scores use stable path ordering.
- [fix] Storage migration handles paths containing backslashes.
- [fix] Search parsing handles multiple matching directories and paths containing backslashes.
- [feature] Frecency scores change continuously between the existing time bands, so results do not jump at exact time boundaries.
- [feature] `$Z_CMD` can be set to `cd`.
- [feature] Completion and manual-page entries include directory opening and purge behavior.
- [maintenance] The README documents both installation methods, common commands, and the current manual.
- [maintenance] CI installs the local plugin before running the integration tests.
- [maintenance] Regression tests cover special paths, invalid input, search modes, cleanup, deletion, and file permissions.

## 2025.12.17

- [feature] Allowed `$Z_CMD` to be set to `cd`.

## 2025.12.16

- [feature] Implemented `..`, `-`, and empty-command behavior to match `cd`.
- [feature] Changed local-directory handling to use an existing local directory instead of jumping.
