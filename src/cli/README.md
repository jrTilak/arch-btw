# Luna CLI

```sh
luna --help
luna theme --help
luna theme list
luna theme current
luna theme install ./my-theme
luna theme install ./my-theme --force
luna theme set tokyo-night
luna completion zsh
```

| Command | Purpose |
| --- | --- |
| `theme list` | List installed themes; copy missing bundled themes into the library |
| `theme current` | Print the active theme name, or `none` |
| `theme install PATH` | Copy a complete theme package; its directory name becomes its identifier |
| `theme install PATH --force` | Replace an installed package after validation |
| `theme set NAME` | Validate and activate an installed theme |
| `completion bash\|zsh\|fish` | Print a shell completion script |

Themes require `base.json`; app overrides in `apps/<app-name>.json` are optional.
Installation preserves the full package and does not activate it. Invalid themes
leave the active selection unchanged. App color generation and reloads are pending.

See [CONVENTIONS.md](../../CONVENTIONS.md) for directory locations and
[theme format](../../themes/README.md) for color roles.
Runtime dependencies are listed in `setup/dependencies.lua`.

Validate CLI behavior:

```sh
python -m unittest discover -s tests -p 'test_cli_theme.py'
```
