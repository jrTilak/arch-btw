# Setup plan

Omarchy is the primary reference for setup organization and desktop workflows.
Adapt its small ordered setup tasks and shared helpers to Lua and portable paths.
Dependencies remain defined in `setup/dependencies.lua`.

## Current scope

`./setup/setup.sh` installs all packages in the current manifest by default,
skipping installed dependencies. The optional `hyprland` scope selects only
`hyprland`, `xdg-desktop-portal-hyprland`, and `wl-clipboard`.
Full setup also deploys the requested minimal Quickshell Polkit agent.
`./setup/setup.sh polkit` installs only its dependencies and login hook.
Keep user-facing setup documentation concise and command-focused.
Full setup also runs `setup/install/stow.lua` to deploy declared Stow packages.
Currently it links only the source packages into `~/.local/src`.
`./setup/setup.sh stow` installs Stow if missing and runs this deployment step.
This step does not back up files or run a dry-run; Stow rejects conflicts.
After moving the checkout, resolve stale source links before rerunning this step.
The Luna CLI provides `theme list`, `current`, `install PATH [--force]`, and
`set NAME`. Theme sources, including bundled themes, live in
`$HOME/.local/share/luna/themes`; the active copy is exposed at
`$HOME/.config/luna/theme`. Theme paths ignore XDG overrides.
The Quickshell top bar reads the active palette and optional `apps/top-bar.json`
overrides. The launcher and Polkit UI are not connected to these colors yet.
`./setup/setup.sh bar` installs native service dependencies and deploys the bar.
`luna-bar serve` starts it; `Super+Ctrl+S` toggles quick settings. Workspace icons
and clock formatting live in the XDG config directory's `luna/top-bar.json`.
Quick settings includes device lists, brightness, battery estimates, and power
actions, with a bounded keyboard focus cycle. `brightnessctl` and `hyprlock` are
bar dependencies. Existing lock configuration is preserved; fallback lock colors
come from the active Luna palette.
Do not run installation commands on the user's behalf unless requested; provide
the terminal command when they want to run setup themselves.

## Deferred candidates

These are ideas to revisit, not authorization to install or implement them.

- Screenshots/color picking: `grim`, `slurp`, `hyprpicker`.
- Additional audio compatibility: `pipewire-pulse`.
- Bluetooth command tools: `bluez-utils`.
- Credentials: `gnome-keyring`, `libsecret`.
- Fonts: `noto-fonts`, `noto-fonts-emoji`.
- CLI tools: `fd`, `fzf`, `bat`, `eza`, `zoxide`, `btop`, `lazygit`.
- Project workflow: `neovim`.

Add groups one at a time as requested. Treat service enablement and app
configuration as separate setup tasks. Hardware-specific choices need detection.
