# dev-desktop

A keyboard-driven developer desktop built on i3, Kitty and Rofi, with one Catppuccin Mocha theme across the window borders, status bar, terminal and launcher. A small shell script shows live CPU, RAM and battery stats in the bar (falling back to disk usage when no battery exists).

## Screenshots

![Desktop](screenshots/desktop.png)
![Launcher](screenshots/launcher.png)

## Setup

Requires Ubuntu or Debian with an X session.

    git clone https://github.com/waffleslately/dev-desktop.git
    cd dev-desktop
    ./install.sh

Then log in to an i3 session, or reload with Mod+Shift+r.

To test inside WSL2:

    sudo apt install -y xserver-xephyr
    Xephyr :1 -screen 1280x720 &
    DISPLAY=:1 i3

On a real Linux install the keybinds work directly. In Xephyr on WSL, some Alt combos may be intercepted by Windows, and apps may need `env -u WAYLAND_DISPLAY` to open inside Xephyr.

## Structure

- config/i3/config: window manager, theme, keybinds, bar
- config/kitty/kitty.conf: terminal theme
- config/rofi/catppuccin.rasi: launcher theme
- scripts/sysinfo.sh: prints CPU, RAM and battery (or disk)
- scripts/statusbar.sh: refreshes the stats every 2 seconds for i3bar
- install.sh: copies everything into place

## Keybindings (Mod = Alt)

| Keys | Action |
|---|---|
| Mod+Enter | Open terminal (Kitty) |
| Mod+d | Open launcher (Rofi) |
| Mod+Shift+q | Close window |
| Mod+h/j/k/l | Move focus |
| Mod+Shift+h/j/k/l | Move window |
| Mod+b / Mod+v | Split horizontal / vertical |
| Mod+f | Fullscreen |
| Mod+Shift+Space | Toggle floating |
| Mod+1..5 | Switch workspace |
| Mod+Shift+1..5 | Move window to workspace |
| Print or Mod+Shift+s | Screenshot |
| Mod+Shift+c / Mod+Shift+r | Reload / restart i3 |

## Theme

Catppuccin Mocha: base #1e1e2e, text #cdd6f4, blue #89b4fa, mauve #cba6f7.

## Stats script

`sysinfo.sh` reads /proc/stat, `free` and /sys/class/power_supply. The bar calls it through `statusbar.sh` every 2 seconds.
![Workspaces](screenshots/workspaces.png)
![Terminal](screenshots/terminal.png)
