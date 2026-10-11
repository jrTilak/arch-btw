# Color themes

Each theme directory contains a `base.json` with the ten shared color tokens.
Colors are opaque `#RRGGBB` values; opacity and blur are configured separately.
Optional `apps/APP-NAME.json` files contain flat objects of app-specific color
overrides, also using `#RRGGBB` values. An override may replace a base role or
provide an extra color token. Token names use letters, digits, and underscores,
starting with a letter or underscore. App generation will resolve these later.

```text
tokyo-night/
  base.json
  apps/                 # Optional; Tokyo Night currently has no overrides.
    top-bar.json
```

Use lowercase letters, digits, hyphens, and underscores for theme identifiers
and app filenames, starting with a letter or digit. Complete packages are copied
into the stable user library; [CLI commands](../src/cli/README.md) install and
activate them. Existing installations require `--force` to replace.

| Base token | Purpose |
| --- | --- |
| `background` | Main app or bar background |
| `surface` | Menus, input fields, and hover backgrounds |
| `foreground` | Main text and icons |
| `muted` | Secondary text and inactive icons |
| `accent` | Active workspaces, focus, and selected controls |
| `onAccent` | Text and icons on an accent background |
| `border` | Outlines and separators |
| `success` | Successful or healthy states |
| `warning` | Caution states |
| `error` | Errors and critical states |

Tokyo Night uses [Omarchy's Tokyo Night palette](https://github.com/omacom/omarchy/blob/dev/themes/tokyo-night/colors.toml).
`surface`, `muted`, and `border` map to `color0`, `color7`, and `color8`;
status colors map to `color2`, `color3`, and `color1`. `onAccent` uses the dark
background color to keep text readable on the blue accent.
