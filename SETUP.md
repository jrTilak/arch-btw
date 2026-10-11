# Setup

Start with an installed Arch Linux system, working networking and mirrors, and
a regular user with sudo access. Run these commands in your own terminal.
The checkout can have any name or location; first change into its directory.

## 1. Install dependencies

For the current Hyprland-only step:

```bash
./setup/setup.sh
```

This installs missing `hyprland`, `xdg-desktop-portal-hyprland`, and
`wl-clipboard` packages. It does not configure the compositor or enable services.

To install the entire agreed manifest, including Git, GitHub CLI, Kitty,
Chromium, and Zen Browser:

```bash
./setup/setup.sh all
```

The launcher installs LuaJIT if missing. Later steps skip installed packages,
reuse yay/paru, and bootstrap yay if neither exists. When official packages are
missing, installation uses a full Arch system upgrade; an already satisfied
setup skips that transaction. Rerunning the same command skips completed work.
Dependency definitions live in `setup/dependencies.lua`.

## 2. Configure Git identity

Complete this after Git is installed. Check existing values first:

```bash
git config --global --get user.name
git config --global --get user.email
```

If missing or incorrect, replace the example values with your identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Use your GitHub-provided noreply email if you prefer to keep your email private.
For an identity specific to this repository, run the same commands with
`--local` instead of `--global` from inside the checkout.

## 3. Authenticate GitHub CLI

GitHub CLI is included in the `all` selection. Check existing authentication:

```bash
gh auth status
```

If already authenticated to the correct account, skip login. Otherwise:

```bash
gh auth login --hostname github.com --git-protocol ssh --web
```

Follow the browser prompts. With SSH selected, gh can offer to create or upload
an SSH key when needed. Git identity and GitHub authentication are separate;
configuring one does not configure the other.

Confirm the result and inspect this repository's remote:

```bash
gh auth status
git remote -v
```

The login command does not rewrite an existing repository's remote URL. If you
prefer HTTPS, select `--git-protocol https` during login and run
`gh auth setup-git` to configure Git to use gh credentials for supported hosts.

## 4. Continue one component at a time

App configuration, theme integration, login hooks, and service enablement are
future steps. This repository currently performs dependency installation only.
`MEMORY.md` records proposed additions that remain deferred.
