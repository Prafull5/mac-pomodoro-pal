# Pomodoro Pal

A tiny native macOS Pomodoro companion. Pick an animated avatar, watch it fill with color during a 25-minute focus session, celebrate when focus ends, and get a prompt after the 10-minute break.

## Run

Clone the repository, then install the command:

```sh
git clone https://github.com/Prafull5/mac-pomodoro-pal.git
cd mac-pomodoro-pal
./install-command
```

Open a new Terminal window, then run from any directory:

```sh
pomodoro
```

From your home directory, `./pomodoro` also works. Without installing the shortcut, launch directly from the cloned directory with:

```sh
./pomodoro
```

The first launch compiles the app and opens a local app bundle. You can close Terminal afterward. Later launches reuse the compiled build when nothing changed. Quit from the menu bar app when you're done.

Requires macOS 14 or newer and Apple's Swift toolchain (Xcode Command Line Tools or Xcode). Install the tools with `xcode-select --install` if `swift` is unavailable.

## Use

- Choose a peach, football, Poké Ball, dumpling, or frog in the main window.
- Press **Start focus**. The small floating companion stays above normal windows and can be dragged anywhere.
- Click the companion, or the timer icon in the menu bar, to reopen the controls.
- After 25 minutes, a celebration appears and the 10-minute break starts automatically.
- At the end of the break, a large prompt invites you to start the next focus session.
- The menu bar offers pause, resume, reset, and quit.

Timing uses wall-clock deadlines, so sessions catch up correctly after the Mac sleeps.
