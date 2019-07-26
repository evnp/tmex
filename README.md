tmux-run
========
[![build status](https://img.shields.io/travis/evnp/tmux-run/master.svg)](https://travis-ci.org/evnp/tmux-run)
[![latest release](https://img.shields.io/github/release/evnp/tmux-run.svg)](https://github.com/evnp/tmux-run/releases/latest)
[![npm package](https://img.shields.io/npm/v/tmux-run.svg)](https://www.npmjs.com/package/tmux-run)
[![license](https://img.shields.io/github/license/evnp/tmux-run.svg)](https://github.com/evnp/tmux-run/blob/master/LICENSE.md)

A minimalist tmux layout manager with zero dependencies.

Manage your entire build pipeline in one view, without extra configuration or yamls. Take the below `start` script:
```
package.json
{
  "name": "special-project"
  "scripts": {
    ..
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
    "start": "tmux new-session -s $npm_package_name 'npm run watch' \\; split-window 'npm run server' \\; split-window 'npm run typecheck'",
  }
  ...
}
```
With `tmux-run`, script compositions are much easier to grok:
```
package.json
{
  "name": "special-project"
  "scripts": {
    ..
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
    "start": "tmux-run -n watch server typecheck",
  }
  ...
}
```

Sane defaults. Layouts with any number of panes. The above splits into:
```
+-----------+-----------+
| npm run   | npm run   |
| watch     | server    |
|           +-----------+
|           | npm run   |
|           | typecheck |
+-----------+-----------+
session : special-project
```

Given 8 commands, tmux-run generates this layout:
```
+-------+-------+-------+
| cmd 1 | cmd 3 | cmd 6 |
|       +---------------+
+-------+ cmd 4 | cmd 7 |
| cmd 2 +---------------+
|       | cmd 5 | cmd 8 |
+-------+-------+-------+
```

Layouts are fully customizable via simple arg listing number of panes in each column:
```
tmux-run <sessionname> --layout=1224
>>>                             |
   1-----2-----2-----4----------+
+-----+-----+-----+-----+
|     |     |     |  f  |
|     |  b  |  d  +-----+
|     |     |     |  g  |
|  a  +-----+-----+-----+
|     |     |     |  h  |
|     |  c  |  e  +-----+
|     |     |     |  i  |
+-----+-----+-----+-----+
```

Left-to-right layout instead of top-to-bottom:
```
tmux-run <sessionname> --layout=1224 --transpose
>>>                             |
+-----------------------+       |
|           a           | 1-----+
|-----------+-----------+ |
|     b     |     c     | 2
|-----------+-----------+ |
|     d     |     e     | 2
|-----+-----+-----+-----+ |
|  f  |  g  |  h  |  i  | 4
+-----+-----+-----+-----+
```

Layouts may be arbitrarily complex via sublayouts [xyz] and custom sizing {xyz}:
```
tmux-run <sessionname> --layout=1[2{13}1]5{41111}
>>>                                 |      |
         +--------------------------+      |
+-----+--|--+-----+-----+                  |
|     |  |        |     |                  |
|     | 1|3       |     | 4----------------+
|     |  |        |     | |
|     +--+--------+-----+ 1
|     |           +-----+ 1
|     |           +-----+ 1
|     |           +-----+ 1
+-----+-----------+-----+
```

Shorthand:
```
tmux-run <sessionname> 1224 "cmd a" "cmd b" "cmd c" etc...
```
Tailor-made for simplifying package.json scripts in npm modules via `--npm|-n` flag:
```
tmux-run -n foo bar baz
>>>
+---------------------------+
| npm run foo | npm run bar |
|             |             |
|             +-------------+
|             | npm run baz |
|             |             |
+-------------+-------------+
session : special-project
```
Session name defaults to `$npm_package_name` if `--npm` option is set. This will expand to match the `name` field set in `package.json`.

Full options list (also accessible via `tmux-run --help`):
```
tmux-run <session-name> \  - session name required unless --npm set; all other args optional
  [-h|--help]
  [-v|--version] \
  [-n|--npm] \                    -n, --npm         if set, prefix each command with "npm run" for package.json scripts
  [-t|--transpose] \              -t, --transpose   build layout in left-to-right orientation instead of top-to-bottom
  [-r|--reattach] \               -r, --reattach    if tmux session already exists, re-attach to it instead of replacing it
  [-p|--print] \                  -p, --print       emit command as string of tmux args instead of invoking tmux directly
  [[-l|--layout] <1-9,[,],{,}>] \ -l, --layout      layout string, each digit represents number of panes in column
  ["shell command 1"] \
  ["shell command 2"] \           - shell commands that will be executed in each pane
  ...                               number of shell commands N must not exceed sum of layout
  ["shell command N"]
```

Running Tests
-------------
Run once:
```
npm install
npm run test
```
Use `fswatch` to re-run tests on file changes:
```
brew install fswatch
npm install
npm run testw
```
For non-OSX, replace `brew install fswatch` with package manager of choice - see [fswatch docs](https://github.com/emcrisostomo/fswatch#getting-fswatch).k
