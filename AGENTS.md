# Project guidance

## Tests

- Add or update a regression test for every functional change.
- Test the public command path when command names or configuration can change.
- Keep tests isolated from the caller's Fish environment.
- Run Fish syntax checks and the Fishtape integration suite before reporting completion.
- If a required test tool cannot run, report that clearly.

## Changelog

- Maintain `CHANGELOG.md` with every user-visible or maintenance change.
- Use flat dated entries with category prefixes such as `[fix]`, `[feature]`, and `[maintenance]`.
- Put new changes under the actual current date.
- Do not move old entries to a new date.
- Confirm the date before adding a new changelog section.

## File safety

- Never use `rm -rf` or any recursive deletion command.
- Do not delete directories in tests. Use synthetic stale records or temporary paths instead.
- Prefer atomic replacement for data-file rewrites.
