# Setup plan

Omarchy is the primary reference for setup organization and desktop workflows.
Adapt its small ordered setup tasks and shared helpers to Lua and portable paths.
Dependencies remain defined in `setup/dependencies.lua`.

## Current scope

The default `./setup/setup.sh` selects only the Hyprland group: `hyprland`,
`xdg-desktop-portal-hyprland`, and `wl-clipboard`. It checks installed packages
and installs missing ones. This does not configure Hyprland or enable services.
`./setup/setup.sh all` explicitly selects the whole agreed manifest.
Do not run installation commands on the user's behalf unless requested; provide
the terminal command when they want to run setup themselves.

## Deferred candidates

These are ideas to revisit, not authorization to install or implement them.

- Screenshots/color picking: `grim`, `slurp`, `hyprpicker`.
- Brightness: `brightnessctl`.
- Audio: `pipewire`, `pipewire-pulse`, `wireplumber`.
- Network/Bluetooth: `networkmanager`, `bluez`, `bluez-utils`.
- Credentials: `gnome-keyring`, `libsecret`.
- Fonts: `noto-fonts`, `noto-fonts-emoji`.
- CLI tools: `fd`, `fzf`, `bat`, `eza`, `zoxide`, `btop`, `lazygit`.
- Project workflow: `neovim`, `stow`.

Add groups one at a time as requested. Treat service enablement and app
configuration as separate setup tasks. Hardware-specific choices need detection.
