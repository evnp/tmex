<p align="center">Lightweight tmux command/layout composer · 1 shell script · 0 dependencies (exc. tmux)</p>

<p align="center">
  <a href="https://github.com/evnp/tmex/issues/12#issuecomment-2725764195">
    <i>Still the best tmux layout manager out there.</i>
  </a> ~&nbsp;<b>@vaygr</b>
</p>

<br>

```
 ______   __    __    ______    __  __
/\__  _\ /\ \  |\ \  /\  ___\  /\_\_\_\
\/_/\ \/ \ \ \ | \ \ \ \  ___\ \/_/\_\/_
   \ \_\  \ \_\ \ \_\ \ \_____\  /\_\/\_\
    \/_/   \/_/  \/_/  \/_____/  \/_/\/_/  tmux execute
```

[![tests](https://github.com/evnp/tmex/workflows/tests/badge.svg)](https://github.com/evnp/tmex/actions)
[![shellcheck](https://github.com/evnp/tmex/workflows/shellcheck/badge.svg)](https://github.com/evnp/tmex/actions)
[![latest release](https://img.shields.io/github/release/evnp/tmex.svg)](https://github.com/evnp/tmex/releases/latest)
[![npm package](https://img.shields.io/npm/v/tmex.svg)](https://www.npmjs.com/package/tmex)
[![license](https://img.shields.io/github/license/evnp/tmex.svg?color=blue)](https://github.com/evnp/tmex/blob/master/LICENSE.md)

**Contents** - [Usage](https://github.com/evnp/tmex#usage) | [Layout](https://github.com/evnp/tmex#layout) | [npm](https://github.com/evnp/tmex#npm) | [Install](https://github.com/evnp/tmex#install) | [Tests](https://github.com/evnp/tmex#tests) | [License](https://github.com/evnp/tmex#license)

**New in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6)** 🐣 <br> [Multi-window management](https://github.com/evnp/tmex#multi-window-management-new-in-v2-) | [Focused-pane control](https://github.com/evnp/tmex#focused-pane-control-new-in-v2-) | [Multi-digit pane counts](https://github.com/evnp/tmex#multi-digit-pane-counts-new-in-v2-) | [Top-level sizing](https://github.com/evnp/tmex#top-level-layout-sizing-new-in-v2-) | [Grid sub-layouts](https://github.com/evnp/tmex#grid-sub-layouts-new-in-v2-)

If you'd like to jump straight to installing tmex, please go to the [Install](https://github.com/evnp/tmex#install) section or try one of these:
```sh
brew install tmex
# OR
npm install -g tmex
# OR to curl directly, see https://github.com/evnp/tmex#install
```

-----------------

Create a dashboard for your project with one command. No messing with configuration files. Just the full power of [`tmux`](https://github.com/tmux/tmux/wiki), plus an easy-yet-flexible layout system:
```sh
tmex -n test lint "npm install"
```

[![asciicast](https://asciinema.org/a/wVlyKFMzbvXYULA34GLskttfc.svg)](https://asciinema.org/a/wVlyKFMzbvXYULA34GLskttfc)

Tailor-made for simplifying unwieldy `package.json` scripts (though tmex works just as well with any arbitrary commands):
```diff
package.json
{
  "name": "special-project"
  "scripts": {
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
-   "start": "tmux new-session -s $npm_package_name 'npm run watch' \\; split-window 'npm run server' \\; split-window 'npm run typecheck'"
+   "start":✨"tmex -n watch server typecheck"✨
  }
}
```
With tmex, `npm run start` composes `watch`, `server`, and `typecheck` into a single view with ease:
```
┌───────────┬───────────┐
│ npm run   │ npm run   │
│ watch     │ server    │
│           ├───────────┤
│           │ npm run   │
│           │ typecheck │
└───────────┴───────────┘
session : special-project
```
Sane defaults. Layouts with any number of panes. Given 8 commands, tmex generates:
```
┌───────┬───────┬───────┐
│ cmd 1 │ cmd 3 │ cmd 6 │
│       ├───────┼───────┤
├───────┤ cmd 4 │ cmd 7 │
│ cmd 2 ├───────┼───────┤
│       │ cmd 5 │ cmd 8 │
└───────┴───────┴───────┘
```

Usage
-----
```sh
tmex your-session-name "cmd a" "cmd b" "cmd c" ... etc.
```
With options and custom layout provided:
```sh
tmex your-session-name --npm --layout=1224 --transpose "cmd a" "cmd b" "cmd c" ... etc.
```
Shorthand:
```sh
tmex your-session-name -nt 1224 "cmd a" "cmd b" "cmd c" ... etc.
                        │     │              │
              options ──┘     └── layout     └── shell commands
```
Session name optional if `--npm` or `-n` is set (will default to package name, [details below](https://github.com/evnp/tmex#npm)):
```
tmex -nt 1224 "cmd a" "cmd b" "cmd c" ... etc.
```
Full options list (also accessible via `tmex -h`):
```
tmex <session-name> ··············  session name required unless --npm or --kill set; all other args optional
  [-h|--help]       [-v|--version]
  [-l|--layout]  0-9 [ ] { } . - +  layout string, each digit represents number of panes in column
  [-f|--focus]   0-9 ·············  tmux pane to select by index, must be an integer, positive or negative
  [-w|--window] "name" ···········  separate sets of tmex args to start session with multiple tmux windows
  [-W|--window-focus] "name" ·····  same as above, but focus this window when session begins
  [-t|--transpose] ···············  build layout in left-to-right orientation instead of top-to-bottom
  [-n|--npm] ·····················  if set, prefix each command with "npm run" for package.json scripts
  [-p|--print] ···················  emit command as string of tmux args instead of invoking tmux directly
  [-d|--detached] ················  invoke tmux with -d (detached session); useful for piping data to tmex
  [-r|--reattach] ················  if tmux session already exists, re-attach to it instead of replacing it
  [-s|--shellless] ···············  if set, invoke commands directly with tmux instead of running inside shell
  [-k|--kill] ····················  kill the current or specified tmux session (all other arguments ignored)
  [-q|--quiet] ···················  suppress any stdout and stderr output from tmex (tmex argument errors will still be logged)
  [-c|--command] "new-session" ···  tmux command that will be called with constructed arguments; default is "new-session"
  [--set-XYZ "value" ] ···········  set tmux option XYZ, eg. "tmex test --set-status=off" -> "tmux -s test ; set status off"
  ["command 1" "command 2" ...] ··  shell commands to be executed in each pane (num commands cannot exceed total pane count)
```

Layout
--------------
If no layout is provided, a sensible default will be generated to match the number of commands provided. However, layouts are fully customizable via `--layout` or `-l` (or as shorthand, the first argument after session name if it is a valid layout):
```sh
tmex your-session-name 1224
# or
tmex your-session-name -l 1224
# or
tmex your-session-name --layout=1224
>>>                             │
   1─────2─────2─────4──────────┘
┌─────┬─────┬─────┬─────┐
│     │     │     │  f  │
│     │  b  │  d  ├─────┤
│     │     │     │  g  │
│  a  ├─────┼─────┼─────┤
│     │     │     │  h  │
│     │  c  │  e  ├─────┤
│     │     │     │  i  │
└─────┴─────┴─────┴─────┘
```
Each digit of `1224` specifies the number of panes each column will be split into. To operate on rows instead of columns, transpose layout left-to-right instead of top-to-bottom with `--transpose` or `-t`:
```sh
tmex your-session-name --transpose --layout=1224
>>>                                         │
┌───────────────────────┐                   │
│           a           │ 1─────────────────┘
├───────────┬───────────┤ │
│     b     │     c     │ 2
├───────────┼───────────┤ │
│     d     │     e     │ 2
├─────┬─────┼─────┬─────┤ │
│  f  │  g  │  h  │  i  │ 4
└─────┴─────┴─────┴─────┘
```

Layouts may be arbitrarily complex via sublayouts `[xyz]` and custom sizing `{xyz}`:
```sh
tmex your-session-name --layout=1[2{13}1]4{4112}
>>>                                 │      │
           ┌────────────────────────┘      │
┌───────┬──│────┬───────┐                  │
│       │  │    │       │                  │
│       │ 1│3   │   4──────────────────────┘
│       │  │    │   │   │
│       ├──┴────┼───1───┤
│       │       ├───1───┤
│       │       ├───│───┤
│       │       │   2   │
└───────┴───────┴───────┘
```
In the example above, the layout `1[2{13}1]4{4112}` contains the sublayout `[2{13}1]` which is constructed in the second column of the full layout. This in turn specifies relative sizing `2{13}` for its first 2 panes, meaning the 2nd pane will be 3x the size of the 1st (denoted by 1, 3 in the diagram above). The 3rd column of the full layout `4{4112}` also defines custom sizing of panes (denoted by 4, 1, 1, 2 in the diagram above).

If you want to change the widths of columns at the top level of the layout, you'll need to prefix the layout with a set of widths:
```sh
tmex your-session-name --layout={152}1[2{13}1]4{4112}
>>>
├─1─┼───────5───────┼──2───┤
┌───┬────┬──────────┬──────┐
│   │    │          │      │
│   │  1 │    3     │  4   │
│   │    │          │      │
│   ├────┴──────────┼──1───┤
│   │               ├──1───┤
│   │               ├──────┤
│   │               │  2   │
└───┴───────────────┴──────┘
```
Note that the sublayout `[2{13}1]` is treated as a single column when sizing is applied, so that set of panes as a whole receives `5` as its width relative to the other columns.

Top-level layout sizing (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
----------------------------------------------------------------------------------------------------
Since a sizing clause like `{123}` always _follows_ a pane count number within a layout, you may be wondering how sizing could be applied to the "top level" columns (or rows) of a layout. For example, given the layout `234`, how could you:
- make the first column `2` fill half the screen
- make the second column `3` fill a third of the screen
- make the third column `4` fill the remainder (one sixth) of the screen

This special case is handled by placing the sizing clause at the _start_ of the layout (prior to [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6), this would result in an invalid layout error):
```sh
tmex your-session-name --layout={321}234
>>>
┌───────────────┬──────────┬─────┐
│               │          │  4  │
│               │    3     │     │
│       2       │          ├─────┤
│               ├──────────┤  4  │
│               │          │     │
├───────────────┤    3     ├─────┤
│               │          │  4  │
│               ├──────────┤     │
│       2       │          ├─────┤
│               │    3     │  4  │
│               │          │     │
└───────────────┴──────────┴─────┘
```
**NOTE:** The same can be accomplished _without_ special casing, using sub-layouts and the transposition feature:
```sh
tmex your-session-name --transpose --layout=[234]{321}    # equivalent to --layout={321}234 above
tmex your-session-name --layout=[[234]{321}]              # also equivalent
```
These may be functionally equivalent, but they're a far cry from intuitive! Feel free to use whichever of the three forms makes the most logical sense to you though.

Grid sub-layouts (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
---------------------------------------------------------------------------------------------

Sometimes you might want a row/column of your layout to contain a grid of N panes, laid out using the default algorithm. This is done by placing `{+}` _after_ a number of panes in the layout. This can be thought of as "requesting a grid layout" for the preceeding number of panes – `+` is a visual mnemonic in that it separates the space within `{ }` in a grid-like formation.
```sh
tmex your-session-name --layout=35{+}4
>>>
┌─────┬─────┬─────┬─────┬─────┐
│     │     │     │     │  4  │
│  3  │     │     │     │     │
│     │     │  5  │  5  ├─────┤
├─────┤     │     │     │  4  │
│     │     │     │     │     │
│  3  │  5  ├─────┼─────┼─────┤
│     │     │     │     │  4  │
├─────┤     │     │     │     │
│     │     │  5  │  5  ├─────┤
│  3  │     │     │     │  4  │
│     │     │     │     │     │
└─────┴─────┴─────┴─────┴─────┘
```
The layout above is equivalent to:
```sh
tmex your-session-name --layout=31224
```
because `5{+}` is expanded to `122`, which is the default grid layout when 5 panes are required. You can experiment with commands such as `tmex your-session-name --layout=7{+}` to see what default grid layout is produced for each number of panes. In general, each default grid layout attempts to equalize pane sizes, widths, and heights as much as possible, keeping the largest pane on the left with odd numbers of panes.

Multi-digit pane counts (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
----------------------------------------------------------------------------------------------------
For any of the layouts above, pane counts 10 and greater can be achieved by separating digits with `.` characters. For example:
```sh
tmex your-session-name --layout=8.10.12
```
will produce a layout of 3 columns, the first with 8 panes, the second with 10 panes, and the third with 12 panes.

These layouts are equivalent (the `.` characters have no effect when used with single-digit pane counts):
```sh
tmex your-session-name --layout=1234
tmex your-session-name --layout=1.2.3.4
```
To understand whether a set of numeric characters will be treated as one multi-digit number, or a series of single-digit numbers, simply ask _Is this set of numeric characters adjacent to a `.` character?_ If so, they are multi-digit numbers; otherwise they are single-digit numbers.

This general rule will help explain this more convoluted (but valid) layout:
```sh
tmex your-session-name --layout=11.[23]45[6.7]8.
#                  multi-digit--^^  ^^|^^ ^|^ ^--multi-digit
#                                     |    |
#                          single-digit    multi-digit
```
`11.` is treated as multi-digit, and produces a column 11 panes. `23` are treated as a sublayout of single-digit pane counts, producing 5 panes total. `45` have no adjacent `.` characters so they produce columns of 4 and 5 panes. `6.7` are treated as multi-digit, but still produce separate rows (in their sublayout) of 6 and 7 panes respectively – the `.` has no effect. Finally, `8.` is treated as multi-digit due to the adjacent `.` but still produces a column of 8 panes – the `.` has no effect).

Focused Pane Control (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
-------------------------------------------------------------------------------------------------

There are a few different ways to select a specific pane to be "focused" – with cursor active inside it – when your layout is initialized.
```sh
tmex your-session-name --layout=135+7
# the above will focus the first pane of the third column of your layout
tmex your-session-name --layout=135++7
# the above will focus the second pane of the third column of your layout
tmex your-session-name --layout=135-7
# the above will focus the last pane of the third column of your layout
tmex your-session-name --layout=135---7
# the above will focus the third-to-last pane of the third column of your layout
```
The above commands focus panes relative to the column they reside in. You can also select a pane to be focused relative to the entire sequence of panes in the layout:
```sh
tmex your-session-name --layout=1357 --focus=4
# the above will focus the first pane of the third column of your layout
# this happens to be equivalent to --layout=135+7 from above
tmex your-session-name --layout=1357 -f=5      # shorthand argument
# the above will focus the second pane of the third column of your layout
# this happens to be equivalent to --layout=135++7 from above
tmex your-session-name -f=-8 1357              # shorthand argument + shorthand layout
# the above will focus the last pane of the third column of your layout
# this happens to be equivalent to --layout=135-7 from above
tmex your-session-name -f=-10 1357             # shorthand argument + shorthand layout
# the above will focus the third-to-last pane of the third column of your layout
# this happens to be equivalent to --layout=135---7 from above
```

Multi-window management (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
----------------------------------------------------------------------------------------------------

You may want to create multiple tmux windows within your tmux session, and navigate between them using **CTRL+B→N** (next), **CTRL+B→P** (previous), **CTRL+B→[0-9]** (select by index).

For example, you might want one window called `abc`, with 6 panes laid out `123`, and a second window called `efg` with 8 panes laid out `44`. To accomplish this, use the `--window` or `-w` option, which is unique in that it can be repeated any number of times within a tmex command:
```sh
tmex your-session-name --window abc 123 -w efg 44
```
Every series of arguments after an instance of `--window` or `-w` is treated as an entirely separate tmex invocation, with separate arguments and commands list. To pass some arguments to the command above (say, to focus panes) and provide some commands, you'd write:
```sh
tmex your-session-name -w abc -f4 123 "cmd a" "cmd b" -w efg -f-2 44 "cmd c"
```
By default, the session will begin with the _first_ window in focus. If you'd like to begin with a different window in focus, simply replace the corresponding `--window` or `-w` arg with `--window-focus` or `-W`, respectively:
```sh
tmex your-session-name --window-focus abc 123 -w efg 44  # focus 1st window
tmex your-session-name --window abc 123 -W efg 44         # focus 2nd window
```
You may be wondering what will happen if you put any args _before_ the first `-w` arg. This will work fine; the command will still produce two windows and the preceeding args will simply be used against the first window:
```sh
tmex your-session-name -l 123 -f4 -w abc "cmd a" "cmd b" -w efg -f-2 44 "cmd c"
# equivalent to command directly above
```
Each `--window` or `-w` argument should be directly followed by the intended name of the window, which will label it in tmux's bottom bar and aid navigation. However, empty-string `''` provided as a name is entirely valid, and there's also a shorthand if you wish to omit a window's name (usually the shell name is used in its place, eg. `bash`):
```sh
tmex your-session-name -w- 123 -w- 44  # produce nameless tmux windows
tmex your-session-name --window - 123 --window - 44       # equivalent
tmex your-session-name -w '' 123 -w '' 44                 # equivalent
tmex your-session-name --window '' 123 --window '' 44     # equivalent
```
**NOTE** that `-w''` (no space between arg and value) does _not_ work, since shell string concatenation causes this to be treated as simply `-w` and the _next_ arg will be inadvertently used as the window name.

**NOTE** that you must _always_ specify a top-level session name when using multiple windows, even if `--npm` / `-n` is specified. This is because npm-mode will be applied on a per-window basis, not to the session as a whole -- necessary if you want to run commands in _some_ windows as NPM scripts, but not commands in _all_ windows.

Usage within tmux sessions (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
---------------------------------------------------------------------------------------------
You can use tmex within an existing tmux session to split panes or create additional windows, using the full suite of layout features. Usage within a tmux session will be automatically detected by tmex, and it will avoid spawning a nested tmux session. You may omit session name from the tmex command in these cases (otherwise it will be ignored):
```sh
# within a tmux session
tmex 123             # split current pane into a 123 layout
tmex -w- 123         # same as above, split current pane within current window
tmex -w- 123 -w- 44  # same as above, and also add a new window with 44 layout
```
There's some possible ambiguity when invoking shell commands with nested tmex calls, since the first command may be treated as a session name and ignored. To avoid this, use `--` to explicitly stop argument parsing and treat all following arguments as shell commands:
```sh
# within a tmux session
tmex "cmd a" "cmd b" "cmd c"   # INCORRECT - "cmd a" treated as session name and ignored
tmex -- "cmd a" "cmd b" "cmd c"  # CORRECT - "cmd a" treated as shell command
```

Kill command (new in [v2](https://github.com/evnp/tmex/releases/tag/v2.0.6) 🐣)
---------------------------------------------------------------------------------------------

You can kill a tmux session from anywhere using
```sh
tmex -k your-session-name
tmex your-session-name -k      # equivalent
tmex your-session-name --kill  # equivalent
```
If you're _inside_ a tmux session at the moment, you can simply write
```
tmex -k
```
The session name will be inferred from current environment variables, and the session will be killed.

npm
------------
Simplify `package.json` scripts via `--npm` or `-n`. Commands will be prefixed with `npm run` (if necessary) and session name will default to `$npm_package_name`. This will expand to match the `name` field set in `package.json`.

**NOTE:** tmux replaces `.`→`_`, `:`→`_`, `\`→`\\` when setting session names, so your final session name may not exactly match the `name` specified in `package.json` (or the name you provide via the `<session-name>` argument at the command line).

```sh
cat package.json | grep name
>>> "name": "special-project"

tmex -n watch server typecheck
>>>
┌───────────┬───────────┐
│ npm run   │ npm run   │
│ watch     │ server    │
│           ├───────────┤
│           │ npm run   │
│           │ typecheck │
└───────────┴───────────┘
session : special-project
```

Install
-------
Homebrew:
```sh
brew install tmex
```
NPM:
```sh
npm install -g tmex
```
curl:
```sh
read -rp $'\n'"Current \$PATH:"$'\n'"${PATH//:/ : }"$'\n\n'"Enter a directory from the list above: " \
  && curl -L -o "${REPLY/\~/$HOME}/tmex" https://github.com/evnp/tmex/raw/main/tmex \
  && chmod +x "${REPLY/\~/$HOME}/tmex"
```
tmex has no external dependencies (other than tmux), but it's good practice to audit code before downloading onto your system to ensure it contains nothing unexpected. Please view the full source code for tmex here: https://github.com/evnp/tmex/blob/master/tmex

If you also want to install tmex's man page:
```sh
read -rp $'\n'"Current \$MANPATH:"$'\n'"${MANPATH//:/ : }"$'\n\n'"Enter a directory from the list above: " \
  && curl -L -o "${REPLY/\~/$HOME}/man1/tmex.1" https://github.com/evnp/tmex/raw/main/man/tmex.1
```
Verify installation:
```sh
tmex -v
==> tmex 2.0.6

brew test tmex
==> Testing tmex
==> /opt/homebrew/Cellar/tmex/2.0.6/bin/tmex test --print 1234 hello world
```

If you see the output `Warning: tmux is not yet installed, tmex will not work without tmux.` you'll need to install tmux as well.
```sh
brew install tmux      # OSX (via Homebrew)
sudo apt install tmux  # Ubuntu, Debian, etc.
```
or refer to [https://github.com/tmux/tmux/wiki/Installing](https://github.com/tmux/tmux/wiki/Installing) for install instructions applicable to your platform.

Tests
-------------
Run once:
```sh
npm install
npm test
```
Use `fswatch` to re-run tests on file changes:
```sh
brew install fswatch
npm install
npm run testw
```
Non-OSX: replace `brew install fswatch` with package manager of choice (see [fswatch docs](https://github.com/emcrisostomo/fswatch#getting-fswatch))

License
-------
MIT

