# Z

**z** is a port of [z](https://github.com/rupa/z) for the [fish shell](https://fishshell.com).

**z** tracks the directories you visit. With a combination of frequency and recency, it enables you to jump to the directory in mind.

A _pure-fish_ port means **z** is _fast_ and _fish-friendly_, with tab-completions and lazy-loading. Top that off with great customizability and a small amount of added functionality.

Originally written by [@jethrokuan](https://github.com/jethrokuan/), co-maintained with [@krobelus](https://github.com/krobelus).

## Features

- Tracks directories using frequency and recency.
- Supports search, list, echo, purge, delete, cleanup, and directory-opening modes.
- Provides Fish completions and configurable data storage.

## Installation

Install with [Reef](https://github.com/danielb2/reef):

```console
reef install danielb2/z
```

Or install with [Fisher](https://github.com/jorgebucaran/fisher):

```console
fisher install danielb2/z
```

## Usage

Common commands include:

```console
z project       # jump to the best match
z -l project   # list matching directories
z -e project   # print the best match without changing directory
z -d project   # open the best match with the file manager
z --typo projcet # opt in to typo-tolerant matching
z -p           # purge all stored entries
z -x           # delete the current directory from the data file
```

See [man/man1/z.md](man/man1/z.md) for all options and configuration details.

Set `Z_TYPO=true` to enable typo-tolerant fallback matching by default. Exact and case-insensitive matches always take priority.

## License

Z is MIT licensed. See the [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the complete project history.
