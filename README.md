```
 ______   __    __    ______    __  __
/\__  _\ /\ \  |\ \  /\  ___\  /\_\_\_\
\/_/\ \/ \ \ \ | \ \ \ \  ___\ \/_/\_\/_
   \ \_\  \ \_\ \ \_\ \ \_____\  /\_\/\_\
    \/_/   \/_/  \/_/  \/_____/  \/_/\/_/  tmux execute
```

[![build status](https://img.shields.io/travis/evnp/tmex/master.svg?style=flat-square)](https://travis-ci.org/evnp/tmex)
[![code quality](https://img.shields.io/badge/code_quality-shellcheck-0cc?style=flat-square)](https://github.com/koalaman/shellcheck)
[![latest release](https://img.shields.io/github/release/evnp/tmex.svg?style=flat-square)](https://github.com/evnp/tmex/releases/latest)
[![npm package](https://img.shields.io/npm/v/tmex.svg?style=flat-square)](https://www.npmjs.com/package/tmex)
[![license](https://img.shields.io/github/license/evnp/tmex.svg?style=flat-square)](https://github.com/evnp/tmex/blob/master/LICENSE.md)

A minimalist tmux layout manager - one shell script, zero dependencies. Manage all your services in one view, without extra configuration files, yaml, etc.

![tmex demo](https://github.com/evnp/tmex/blob/master/tmex.gif?raw=true)

Tailor-made for simplifying `package.json` scripts (though tmex works just as well with any arbitrary commands).
Consider the `start` script below:
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
[tmex](https://raw.githubusercontent.com/evnp/tmex/master/tmex) has no external dependencies, but always read code before downloading to ensure it contains nothing unexpected.

Custom layouts
--------------
Layouts are fully customizable via arg listing number of panes in each column:
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

Transpose layout left-to-right instead of top-to-bottom:
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

Layouts may be arbitrarily complex via sublayouts [xyz] and custom sizing {xyz}:
```
tmex <sessionname> --layout=1[2{13}1]4{4112}
>>>                             |      |
         +----------------------+      |
+-----+--|--------+-----+              |
|     |  |        |     |              |
|     | 1|3       |     | 4------------+
|     |  |        |     | |
|     +--+--------+-----+ 1
|     |           +-----+ 1
|     |           +-----+ |
|     |           |     | 2
+-----+-----------+-----+
```

Shorthand:
```
tmex <sessionname> 1224 "cmd a" "cmd b" "cmd c" etc...
```

NPM packages
===
Simplify `package.json` scripts via `--npm|-n` flag. Commands will be prefixed with `npm run` (if necessary) and session name will default to `$npm_package_name`. This will expand to match the `name` field set in `package.json`.
```
cat package.json | grep name
>>> special-project

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
Usage: tmex <session-name>         - session name required unless --npm set; all other args optional
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

Running tests
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
