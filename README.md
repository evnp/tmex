```
 ______   __    __    ______    __  __
/\__  _\ /\ \  |\ \  /\  ___\  /\_\_\_\
\/_/\ \/ \ \ \ | \ \ \ \  ___\ \/_/\_\/_
   \ \_\  \ \_\ \ \_\ \ \_____\  /\_\/\_\
    \/_/   \/_/  \/_/  \/_____/  \/_/\/_/  tmux execute
```

[![build status](https://img.shields.io/travis/evnp/tmex/master.svg?style=flat-square)](https://travis-ci.org/evnp/tmex)
[![code quality](https://img.shields.io/badge/code_quality-shellcheck-7cf?style=flat-square)](https://github.com/koalaman/shellcheck)
[![latest release](https://img.shields.io/github/release/evnp/tmex.svg?style=flat-square)](https://github.com/evnp/tmex/releases/latest)
[![npm package](https://img.shields.io/npm/v/tmex.svg?style=flat-square)](https://www.npmjs.com/package/tmex)
[![license](https://img.shields.io/github/license/evnp/tmex.svg?style=flat-square&color=blue)](https://github.com/evnp/tmex/blob/master/LICENSE.md)

**Contents** - [Usage](https://github.com/evnp/tmex#usage) | [Layout](https://github.com/evnp/tmex#layout) | [npm](https://github.com/evnp/tmex#npm) | [Install](https://github.com/evnp/tmex#install) | [Tests](https://github.com/evnp/tmex#tests) | [License](https://github.com/evnp/tmex#license)

A minimalist tmux layout manager - one shell script, zero dependencies.

Manage all your services in one view, without extra configuration files, yaml, etc. plus an intuitive, flexible layout system.

![tmex demo](https://github.com/evnp/tmex/blob/master/tmex.gif?raw=true)

Tailor-made for simplifying `package.json` scripts, though tmex works just as well with any arbitrary commands:
```diff
package.json
{
  "name": "special-project"
  "scripts": {
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
-   "start": "tmux new-session -s $npm_package_name 'npm run watch' \\; split-window 'npm run server' \\; split-window 'npm run typecheck'"
+   "start": ✨"tmex -n watch server typecheck"✨
  }
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

Usage
-----
```
tmex <session-name> "cmd a" "cmd b" "cmd c" ... etc.
```
With options and custom layout provided:
```
tmex <session-name> -nt 1224 "cmd a" "cmd b" "cmd c" ... etc.
                     |     |              |
           options --+     +-- layout     +-- shell commands
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
  [-s|--shellless]                 -s, --shellless   if set, invoke commands directly with tmux instead of running inside shell
  ["shell command 1"]
  ["shell command 2"]              - shell commands that will be executed in each pane
  ...                                number of shell commands N must not exceed sum of layout
  ["shell command N"]
```

Layout
--------------
If no layout is provided, a sensible default will be generated to match the number of commands provided. However, layouts are fully customizable via `--layout|-l`:
```
tmex <sessionname> --layout=1224
>>>                         |
   1-----2-----2-----4------+
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
Each digit of `1224` specifies the number of panes each column will be split into. To operate on rows instead of columns, transpose layout left-to-right instead of top-to-bottom with `--transpose|-t`:
```
tmex <sessionname> --transpose --layout=1224
>>>                                     |
+-----------------------+               |
|           a           | 1-------------+
+-----------+-----------+ |
|     b     |     c     | 2
+-----------+-----------+ |
|     d     |     e     | 2
+-----+-----+-----+-----+ |
|  f  |  g  |  h  |  i  | 4
+-----+-----+-----+-----+
```

Layouts may be arbitrarily complex via sublayouts `[xyz]` and custom sizing `{xyz}`:
```
tmex <sessionname> --layout=1[2{13}1]4{4112}
>>>                             |      |
         +----------------------+      |
+-----+--|--------+-----+              |
|     |  |        |     |              |
|     | 1|3       |  4-----------------+
|     |  |        |  |  |
|     +--+--------+--1--+
|     |           +--1--+
|     |           +--|--+
|     |           |  2  |
+-----+-----------+-----+
```
In the example above, the layout `1[2{13}1]4{4112}` contains the sublayout `2{13}1` which is constructed in the second column of the full layout. This in turn specifies relative sizing `2{13}` for its first 2 panes, meaning the 2nd pane will be 3x the size of the 1st (denoted by 1, 3 in the diagram above). The 3rd column of the full layout `4{4112}` also defines custom sizing of panes (denoted by 4, 1, 1, 2 in the diagram above).

npm
------------
Simplify `package.json` scripts via `--npm|-n`. Commands will be prefixed with `npm run` (if necessary) and session name will default to `$npm_package_name`. This will expand to match the `name` field set in `package.json`.
```
cat package.json | grep name
>>> "name": "special-project"

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
# or /usr/local/bin or other bin of your choice (as long it's in your $PATH)
```
[tmex](https://raw.githubusercontent.com/evnp/tmex/master/tmex) has no external dependencies other than tmux, but always read code before downloading to ensure it contains nothing unexpected.

Tests
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

License
-------
MIT
