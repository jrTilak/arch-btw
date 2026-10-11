# Luna CLI scaffold

Run from the checkout:

```sh
./bin/luna --help
./bin/luna theme --help
./bin/luna theme set --help
./bin/luna completion zsh
```

Help and completion work. `theme list`, `theme current`, and `theme set NAME`
are placeholders that return a nonzero status without changing configuration.
The CLI is not deployed into `~/.local/bin` by setup yet.

Runtime requirements: LuaJIT, `lua51-argparse`, Bash, and coreutils, maintained
in `setup/dependencies.lua`. Full setup installs these dependencies.
For an existing Arch installation missing only the CLI runtime:

```sh
sudo pacman -S --needed luajit lua51-argparse
```

Use the Lua 5.1 argparse package for LuaJIT, rather than `lua-argparse`.
