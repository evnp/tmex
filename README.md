A lightweight tmux command & layout composer - one shell script + tmux + zero other dependencies

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

**New in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3)** 🐣 <br> [Multi-window management](https://github.com/evnp/tmex#multi-window-management-new-in-v200-rc3-) | [Focused-pane control](https://github.com/evnp/tmex#focused-pane-control-new-in-v200-rc3-) | [Multi-digit pane counts](https://github.com/evnp/tmex#multi-digit-pane-counts-new-in-v200-rc3-) | [Top-level sizing](https://github.com/evnp/tmex#top-level-layout-sizing-new-in-v200-rc3-) | [Grid sub-layouts](https://github.com/evnp/tmex#grid-sub-layouts-new-in-v200-rc3-)

-------------
Create a dashboard for your project with one command. No messing with configuration files. Just the full power of [`tmux`](https://github.com/tmux/tmux/wiki), plus an easy-yet-flexible layout system:
```sh
tmex -n test lint "npm install"
```

![tmex demo](https://github.com/evnp/tmex/blob/master/tmex.gif?raw=true)

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
tmex <session-name>                - session name required unless --npm set; all other args optional
  [-h|--help]
  [-v|--version]
  [[-l|--layout] <1-9,[,],{,}>]    -l, --layout      layout string, each digit represents number of panes in column
  [-t|--transpose]                 -t, --transpose   build layout in left-to-right orientation instead of top-to-bottom
  [-n|--npm]                       -n, --npm         if set, prefix each command with "npm run" for package.json scripts
  [-p|--print]                     -p, --print       emit command as string of tmux args instead of invoking tmux directly
  [-d|--detached]                  -d, --detached    invoke tmux with -d (detached session); useful for piping data to tmex
  [-r|--reattach]                  -r, --reattach    if tmux session already exists, re-attach to it instead of replacing it
  [-k|--kill]                      -k, --kill        kill the current or specified tmux session (all other arguments ignored)
  [-s|--shellless]                 -s, --shellless   if set, invoke commands directly with tmux instead of running inside shell
  ["shell command 1"]
  ["shell command 2"]              - shell commands that will be executed in each pane
  ...                                number of shell commands N must not exceed sum of layout
  ["shell command N"]
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

Top-level layout sizing (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
----------------------------------------------------------------------------------------------------
Since a sizing clause like `{123}` always _follows_ a pane count number within a layout, you may be wondering how sizing could be applied to the "top level" columns (or rows) of a layout. For example, given the layout `234`, how could you:
- make the first column `2` fill half the screen
- make the second column `3` fill a third of the screen
- make the third column `4` fill the remainder (one sixth) of the screen

This special case is accomplished by placing the sizing clause at the _start_ of the layout (prior to [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3), this would result in an invalid layout error):
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
**NOTE:** This can be accomplished _without_ special casing, using sub-layouts and the transposition feature:
```sh
tmex your-session-name --transpose --layout=[234]{321}    # equivalent to --layout={321}234 above
tmex your-session-name --layout=[[234]{321}]              # also equivalent
```
These may be functionally equivalent, but they're a far cry from intuitive! Feel free to use whichever of the three forms makes the most logical sense to you though.

Grid sub-layouts (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
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

Multi-digit pane counts (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
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

Focused Pane Control (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
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

Multi-window management (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
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

Kill command (new in [v2.0.0-rc.3](https://github.com/evnp/tmex/releases/tag/v2.0.0-rc.3) 🐣)
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
The session name will be inferred from the current ENV variables, and the session will be killed.

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
Install as a build tool in a package:
```sh
npm install --save-dev tmex
```
Install globally for use with any set of `package.json` scripts or arbitrary commands:
```sh
npm install -g tmex
```
or sans-npm:
```sh
curl -o ~/bin/tmex https://raw.githubusercontent.com/evnp/tmex/master/tmex && chmod +x ~/bin/tmex
# or /usr/local/bin or other bin of your choice (as long it's in your $PATH)
```
[tmex](https://raw.githubusercontent.com/evnp/tmex/master/tmex) has no external dependencies other than tmux, but always read code before downloading to ensure it contains nothing unexpected.

tmex doesn't install tmux itself, so you'll also want to do that if you don't have tmux yet:
```sh
tmex -n test lint "npm install"
>>> /Users/evan/bin/tmex: line 694: tmux: command not found

brew install tmux      # OSX
sudo apt install tmux  # Ubuntu, Debian
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

