# Color themes

Each theme's `theme.json` contains a display name and a shared `base` palette.
Colors are opaque `#RRGGBB` values; opacity and blur are configured separately.
These files currently define palettes only; activation and app loading are not
implemented yet.

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
