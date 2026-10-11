# Setup

Run from the repo directory on Arch Linux as your normal user with sudo access.

## 1. Install dependencies

```bash
./setup/setup.sh
```

Installs all packages in `setup/dependencies.lua`, skipping installed ones.
Reuses yay/paru or installs yay if needed.
Also links the Polkit agent and adds its login hook to your existing Hyprland
Lua config, backing up conflicts. Restart the agent after moving/relinking the repo.

## 2. Configure Git

Use your name and email; skip if already configured.

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

## 3. Connect GitHub

Skip login if `gh auth status` shows the correct account.

```bash
gh auth login --hostname github.com --git-protocol ssh --web
gh auth status
```

## Polkit agent

Set up only the agent, then start it now:

```bash
./setup/setup.sh polkit
~/.local/bin/polkit-agent
```

It starts automatically at future Hyprland logins. Test the GUI password prompt:

```bash
pkexec --disable-internal-agent /usr/bin/true
```

Enter authenticates; Escape or Cancel dismisses. Terminal sudo keeps its normal
prompt. Rerun agent setup after moving the checkout to refresh its links.
