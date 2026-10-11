# Luna

Personal Arch Linux + Hyprland desktop customization project. Develop gradually,
including custom apps built with Quickshell or other explicitly chosen toolkits.

The desktop customization project is named **Luna**. Use `luna` as the intended
CLI command name and Luna in user-facing branding. The checkout directory may
retain its existing name; do not derive command names or resource paths from it.

## Working rules

- Only make changes the user explicitly requests. Do not add unrelated features,
  install dependencies, or change system settings outside the requested scope.
- Work one step at a time. A request for information or a list does not authorize
  installation or implementation.
- Keep mockups separate from real system controls. Mockups must not modify system
  settings unless the user explicitly requests that integration.
- Prefer native tools and avoid unnecessary runtime dependencies. Discuss new
  runtime requirements when selecting a stack; QML's embedded JavaScript is fine.
- Favor sharp, square UI styling. Preserve established choices unless asked to
  change them.
- Preserve existing user configuration. Back up files before replacing them and
  keep scripts safe to run repeatedly.
- Validate configuration and relevant behavior after changes. Reload Hyprland and
  check `hyprctl configerrors` after editing its configuration.
- Do not create `.gitkeep` files.

## Primary reference

Use [Omarchy](https://github.com/omacom/omarchy) as the primary implementation
reference for this project's setup, desktop configuration, theming, helpers,
and application workflows. Its former URL, `https://github.com/basecamp/omarchy`,
redirects to this repository.

When relevant, inspect Omarchy's corresponding code and learn from or adapt its
ideas before inventing a new approach. Fit adaptations to this project's chosen
stack, portable paths, styling, and requested scope. Preserve applicable license
notices when reusing code and link to the source when it helps explain a decision.
The user's instructions and this project's conventions take precedence over
Omarchy's defaults; using it as a reference does not authorize installing it.

## Current scope and layout

The repository contains dependency setup and a real minimal Quickshell Polkit
authentication agent. Preferences, settings mockups, and theme helpers were
removed; do not recreate them unless requested.

- `setup/`: Bootstrap and dependency manifest. `install/` holds ordered Lua
  setup steps; `helpers/` holds shared command utilities.
- `MEMORY.md`: Deferred package groups and current implementation scope.
- `.agents/skills/`: Project-local assistant skills.
- `src/polkit-agent/`: Native Polkit flow and minimal authentication UI.
- `src/top-bar/`: Quickshell bar, workspace icons, and native quick settings.
- `bin/polkit-agent`: Stable session agent command.
- `config/hypr/`: Agent login module, loaded from the user's XDG config path.

Use Lua for setup logic. `setup/setup.sh` is the small bootstrap launcher
that installs LuaJIT if missing and runs `setup/install/all.lua`.
Maintain required setup and runtime dependencies in `setup/dependencies.lua`,
grouped by installation source. Setup installs the full manifest by default.
Keep user-facing documentation concise and command-focused.
Full setup also deploys the explicitly requested Polkit agent and login module.
Other configuration migration remains separate; do not restore a root
`install.sh` entry point. `setup.sh polkit` selects only the agent setup.
Do not assume AUR tooling is already set up: verify sudo access, install missing
git/base-devel prerequisites, and reuse yay/paru if present. If neither exists,
bootstrap yay with makepkg as the regular user, then install all manifest AUR
packages through yay. Do not add an AUR repository to pacman.conf.
`setup.sh bar` installs the bar dependencies, Stows sources, and deploys its
command, editable settings, and Hyprland login module. Full setup includes it.

Use sudo for visible terminal operations and Polkit/pkexec for GUI privileged
actions. Keep the authentication agent unprivileged; Polkit/PAM own permission
decisions. Never log, store, or send password responses to command arguments.
Do not disable or kill other authentication agents without authorization.

Use the local `comment-code` skill when writing or editing code and configuration.
Add meaningful explanations and blank lines between logical sections, keeping
each comment next to the code it explains.

The checkout can have any name and live anywhere. Resolve checkout resources
relative to the executing script, following symlinks, rather than assuming
`~/arch-btw`, a fixed working directory, or a particular username. Quote paths
so spaces and apostrophes work.

Use stable consumer paths under the user's home/XDG directories: configuration
under `${XDG_CONFIG_HOME:-$HOME/.config}`, data under
`${XDG_DATA_HOME:-$HOME/.local/share}`, state under
`${XDG_STATE_HOME:-$HOME/.local/state}`, and cache under
`${XDG_CACHE_HOME:-$HOME/.cache}`. User commands go in `~/.local/bin`.
Links into a checkout must be refreshed after moving it; stable consumer paths
stay the same.
Luna themes are an explicit exception: use `$HOME/.local/share/luna/themes`
for the library and `$HOME/.config/luna/theme` for the active theme, ignoring
XDG directory overrides.
Leave the separate `~/dotfiles` repository alone unless explicitly requested.

## Skills to consider later

These are planning notes, not authorization to create or install skills.

### Proposed custom skills

| Skill | Intended scope |
| --- | --- |
| Hyprland configuration | Lua configuration, keybindings, window rules, monitors, gaps, opacity, blur, reloads, and error checks. |
| Quickshell development | QML components, embedded JavaScript, keyboard navigation, system services, app lifecycle, and previews. |
| Desktop theming | Shared palettes, GTK/Qt appearance, and dark/light switching. |
| Dotfiles management | `config/` and `src/` organization, Stow links, portable setup, and repeatable scripts. |
| Native app development | Build and validate apps using the language/toolkit chosen for the specific app. |

Start with Hyprland configuration, Quickshell development, and dotfiles management
when the user requests skill creation.

### Existing skills to consider

- `skill-creator`: Available in the current session for creating/updating skills.
- `screenshot`: Official installable skill for visual checks; verify its support
  for the current Wayland environment before using it.
- `figma`: Official installable skill if the user chooses Figma as a design source.

At the time of planning, the official curated catalog did not contain dedicated
Hyprland or Quickshell skills. Recheck availability before installation. Skills
guide the coding assistant; they are not runtime dependencies of the desktop.
