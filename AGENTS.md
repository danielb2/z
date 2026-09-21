# Project guidance

## Tests

- Add or update a regression test for every functional change.
- Test the public command path when command names or configuration can change.
- Keep tests isolated from the caller's Fish environment.
- Run the relevant tests after every code change.
- Run Fish syntax checks and the Fishtape integration suite before reporting completion.
- If a required test tool cannot run, report that clearly.
- Run the relevant tests again before every commit.
- Require functional 100% coverage for every change: test every new option form, default value, valid value, invalid value, error path, boundary, and public command route introduced or modified.
- Do not treat a happy-path assertion as coverage for a feature. Add assertions for the observable result and side effects, including unchanged state where relevant.
- Run the complete affected test suite after the final implementation and after the final test edit; never report unrun tests as passing.

## Changelog

- Maintain `CHANGELOG.md` with every user-visible or maintenance change.
- Use flat dated entries with category prefixes such as `[fix]`, `[feature]`, and `[maintenance]`.
- Put new changes under the actual current date.
- Do not move old entries to a new date.
- Confirm the date before adding a new changelog section.

## Compatibility

- Keep Fish scripts portable across supported Fish versions and platforms.
- Avoid new external dependencies unless the benefit and installation path are documented.
- Preserve legacy data when changing the storage format; add migration tests.

## Documentation

- Update the README and manual pages when commands, options, configuration, or behavior change.
- Do not report a test as passing unless it actually ran; distinguish unavailable tools from failed tests.

## File safety

- Never use `rm -rf` or any recursive deletion command.
- Do not delete directories in tests. Use synthetic stale records or temporary paths instead.
- Prefer atomic replacement for data-file rewrites.
