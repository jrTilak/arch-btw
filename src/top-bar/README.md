# Luna top bar

```sh
./setup/setup.sh bar
luna-bar serve
luna-bar controls
luna-bar close
```

- Left: workspace icons. Click to switch; the active workspace has a thin underline.
- Center: date and time. No calendar popup.
- Right: grouped status icons. Click or press **Super+Ctrl+S** for quick settings.
- Quick settings: Wi-Fi networks, paired Bluetooth devices, audio output/input
  selection and mute, volume, brightness, battery percentage and time remaining.
- Click a tile for devices; its small button toggles the radio or mute state.
- Lock, suspend, restart, and shut down are under power. Power actions ask for
  confirmation. Lock uses existing Hyprlock settings, or a Luna-colored fallback.

Keyboard: **Tab / Shift+Tab** cycle within the panel; **arrow keys** move between
tiles, select list rows, or adjust sliders. **Enter / Space** activate buttons or
list rows. **Home / End** reach list/slider limits. **Escape** cancels password
entry, goes back, or closes the main panel. No tooltip text.

Wi-Fi supports saved networks, open networks, and password-based networks.
Enterprise networks must first be configured in NetworkManager. Bluetooth lists
paired devices; pairing new devices remains outside this control center.

Settings: `${XDG_CONFIG_HOME:-$HOME/.config}/luna/top-bar.json`.
Edit `workspaceIcons`, `persistentWorkspaces`, `fontFamily`, or `clockFormat`;
changes reload automatically. Workspace icons accept the bundled names below
or desktop icon-theme names, such as `firefox` and `org.kde.dolphin`.
Use an empty icon string to show the workspace number.

Bundled workspace icons: `browser`, `code`, `terminal`, `chat`, `folder`.
`defaults.json` contains the initial settings copied by setup.

Colors: `$HOME/.config/luna/theme/base.json`, with optional
`apps/top-bar.json` overrides. Extra roles: `workspaceActive` and
`workspaceInactive`. Theme changes reload within 1.5 seconds; Tokyo Night is
the fallback when no theme has been activated. Backgrounds are opaque.

Sources: `$HOME/.local/src/top-bar` (Stow). Setup adds the login module and
preserves existing workspace/media shortcuts and app agents. Service backends
are declared in `setup/dependencies.lua`; setup does not enable them. Missing
services disable the corresponding controls.

Workspace lookup/ordering is adapted from [Omarchy's Quickshell widget](https://github.com/omacom/omarchy/blob/be7c7bf3785f11c9f2dc210824cdf912ec4af043/shell/plugins/bar/widgets/Workspaces.qml).
See `OMARCHY-LICENSE` for its MIT notice. The interface and native service
integration are Luna code; no Omarchy shell host or helper commands are required.

Checks:

```sh
python -m unittest discover -s tests
python tests/run_bar_keyboard.py
```
