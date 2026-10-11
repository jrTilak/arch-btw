# Desktop ricing plan

Build a personal Arch + Hyprland desktop one component at a time. Each phase
should produce something usable before moving on. Borrow useful ideas from
Omarchy while keeping setup small and portable: clone, run scripts, and use it
on another Arch machine. No custom distribution or installation image is needed.

## 1. Basic system foundation

- Audit audio, networking, Bluetooth, clipboard, screen sharing, brightness,
  fonts, authentication, and session startup.
- Preserve working setup and fill only the gaps we choose to address.
- Record required dependencies and repeat-safe setup steps.
- Dependency installation and the minimal Polkit overlay are already started.

## 2. Hyprland behavior

- Configure monitor resolution, refresh rate, and scaling.
- Establish window movement, resizing, closing, fullscreen, and focus behavior.
- Set workspace navigation and shortcuts for moving windows between workspaces.
- Organize app shortcuts, startup commands, gaps, and borders.
- Separate machine-specific monitor settings from shared defaults.
- Preserve useful existing choices; reload and check configuration errors.

## 3. Shared visual foundation

- Choose dark/light backgrounds, text colors, and an accent color.
- Select UI and monospace fonts.
- Define spacing, control heights, border widths, and sharp corners.
- Establish consistent hover/focus states and animation timing.
- Decide where transparency and blur help.
- Keep tokens small initially; expand them when a component needs more.

## 4. Kitty and shell

- Style Kitty colors, font, padding, cursor, selection, and shortcuts.
- Configure Zsh prompt, history, completion, and useful aliases.
- Add selected terminal tools as needed.
- Use the terminal as the first finished app to test the visual foundation.

## 5. Desktop shell components

Build minimal working versions, then refine their appearance using shared tokens.

| Order | Component | Initial scope |
| --- | --- | --- |
| 1 | Wallpaper | Set a wallpaper and restore it at login |
| 2 | Launcher | Find and launch apps with keyboard navigation |
| 3 | Bar | Workspaces, clock, battery, audio, and network status |
| 4 | Notifications | Read, dismiss, and review notifications |
| 5 | Control center | Working audio, brightness, and connectivity controls |

## 6. Screenshots, locking, and idle

- Add reliable screenshot shortcuts.
- Configure lock screen, idle timeout, and suspend behavior.
- Check interactions with fullscreen apps and screen sharing.

## 7. Settings app

- Start with appearance and Hyprland preferences, then add pages gradually.
- Reintroduce shared preferences when implementing actual settings controls.
- Use defaults, saved preferences, and handwritten overrides with clear precedence.
- Validate values and establish application behavior before expanding controls.
- Clearly show overridden values; keep mockups separate from real controls.

## 8. App consistency and polish

- Apply the visual system to GTK/Qt apps, browsers, icons, and cursors.
- Configure Neovim when its migration is requested.
- Refine animations, menus, and the Polkit overlay as the design settles.
- Finish each app individually rather than changing everything at once.

## Working approach

- Record dependencies as features need them.
- Keep code and configuration readable with meaningful comments and section spacing.
- Make setup repeat-safe, preserve user files, and use portable home/XDG paths.
- Validate each completed feature before moving to the next.
- This plan records intended work; implement each step when requested.

Next: audit the basic system foundation, then address its gaps before working on
Hyprland behavior and shared UI tokens.
