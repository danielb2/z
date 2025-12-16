# Z

**z** is a port of [z](https://github.com/rupa/z) for the [fish shell](https://fishshell.com).

**z** tracks the directories you visit. With a combination of frequency and recency, it enables you to jump to the directory in mind.

A _pure-fish_ port means **z** is _fast_ and _fish-friendly_, with tab-completions and lazy-loading. Top that off with great customizability and a small amount of added functionality.

Originally written by [@jethrokuan](https://github.com/jethrokuan/), co-maintained with [@krobelus](https://github.com/krobelus).

## Notes

The project by [@jethrokuan](https://github.com/jethrokuan/) appears dead, so I'm not even bothering doing a PR

## Installation

Install with [reef](https://github.com/danielb2/reef): or [Fisher](https://github.com/jorgebucaran/fisher):

```console
reef install danielb2/z
```

## Usage

See [man/man1/z.md](https://github.com/danielb2/z/blob/master/man/man1/z.md) for details.

## License

Z is MIT licensed. See the [LICENSE](LICENSE) for details.

## ChangeLog
- 2025.12.16: implement `..`, `-` and empty command symantics to mimick those of `cd`
