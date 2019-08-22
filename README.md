tmex
========
[![build status](https://img.shields.io/travis/evnp/tmex/master.svg)](https://travis-ci.org/evnp/tmex)
[![code style](https://img.shields.io/badge/code_style-shellcheck-0cc)](https://github.com/koalaman/shellcheck)
[![latest release](https://img.shields.io/github/release/evnp/tmex.svg)](https://github.com/evnp/tmex/releases/latest)
[![npm package](https://img.shields.io/npm/v/tmex.svg)](https://www.npmjs.com/package/tmex)
[![license](https://img.shields.io/github/license/evnp/tmex.svg)](https://github.com/evnp/tmex/blob/master/LICENSE.md)

A minimalist tmux layout manager - one shell script, zero dependencies.

Manage all your services in one view, without extra configuration files, yaml, etc. Take the `start` script below:
```diff
package.json
{
  "name": "special-project"
  "scripts": {
    ..
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
-   "start": "tmux new-session -s $npm_package_name 'npm run watch' \\; split-window 'npm run server' \\; split-window 'npm run typecheck'"
+   "start": "tmex -n watch server typecheck"
  }
  ...
}
```
With tmex, `npm run start` composes `watch`, `server`, and `typecheck` into a single view with ease:
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
Sane defaults. Layouts with any number of panes. Given 8 commands, tmex generates:
```
+-------+-------+-------+
| cmd 1 | cmd 3 | cmd 6 |
|       +---------------+
+-------+ cmd 4 | cmd 7 |
| cmd 2 +---------------+
|       | cmd 5 | cmd 8 |
+-------+-------+-------+
```

Install
-------
Install as a build tool in a package:
```
npm install --save-dev tmex
```
Install globally for use with any set of `package.json` scripts or arbitrary commands:
```
npm install -g tmex
```
or sans-npm:
```
curl -o ~/bin/tmex https://raw.githubusercontent.com/evnp/tmex/master/tmex && chmod +x ~/bin/tmex
# or /usr/local/bin or other bin of your choice
```
[tmex](https://raw.githubusercontent.com/evnp/tmex/master/tmex) has no external dependencies, but always read code before downloading to ensure it contains nothing unexpected.

Custom layouts
--------------
Layouts are fully customizable via arg listing number of panes in each column:
```
tmex <sessionname> --layout=1224
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

Transpose layout left-to-right instead of top-to-bottom:
```
tmex <sessionname> --layout=1224 --transpose
>>>                             |
+-----------------------+       |
|           a           | 1-----+
+-----------+-----------+ |
|     b     |     c     | 2
+-----------+-----------+ |
|     d     |     e     | 2
+-----+-----+-----+-----+ |
|  f  |  g  |  h  |  i  | 4
+-----+-----+-----+-----+
```

Layouts may be arbitrarily complex via sublayouts [xyz] and custom sizing {xyz}:
```
tmex <sessionname> --layout=1[2{13}1]5{41111}
>>>                                 |      |
         +--------------------------+      |
+-----+--|--------+-----+                  |
|     |  |        |     |                  |
|     | 1|3       |     | 4----------------+
|     |  |        |     | |
|     +--+--------+-----+ 1
|     |           +-----+ 1
|     |           +-----+ 1
|     |           +-----+ 1
+-----+-----------+-----+
```

Shorthand
---------
```
tmex <sessionname> 1224 "cmd a" "cmd b" "cmd c" etc...
```
Tailor-made for simplifying package.json scripts in npm modules via `--npm|-n` flag. Session name defaults to `$npm_package_name` if `--npm` option is set. This will expand to match the `name` field set in `package.json`.
```
tmex -n watch server typecheck
>>>
+-----------+-----------+
| npm run   | npm run   |
| watch     | server    |
|           +-----------+
|           | npm run   |
|           | typecheck |
+-----------+-----------+
session : special-project
```

Full options list (also accessible via `tmex --help`):
```
tmex <session-name>                - session name required unless --npm set; all other args optional
  [-h|--help]
  [-v|--version]
  [-n|--npm]                       -n, --npm         if set, prefix each command with "npm run" for package.json scripts
  [-t|--transpose]                 -t, --transpose   build layout in left-to-right orientation instead of top-to-bottom
  [-r|--reattach]                  -r, --reattach    if tmux session already exists, re-attach to it instead of replacing it
  [-p|--print]                     -p, --print       emit command as string of tmux args instead of invoking tmux directly
  [[-l|--layout] <1-9,[,],{,}>]    -l, --layout      layout string, each digit represents number of panes in column
  ["shell command 1"]
  ["shell command 2"]              - shell commands that will be executed in each pane
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
Non-OSX: replace `brew install fswatch` with package manager of choice (see [fswatch docs](https://github.com/emcrisostomo/fswatch#getting-fswatch))
