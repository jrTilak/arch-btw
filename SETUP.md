# Setup

Run from the repo directory on Arch Linux as your normal user with sudo access.

## 1. Install dependencies

```bash
./setup/setup.sh
```

Installs all packages in `setup/dependencies.lua`, skipping installed ones.
Reuses yay/paru or installs yay if needed.

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
