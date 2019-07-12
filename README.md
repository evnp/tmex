tmux-run
========
A minimalist layout wrapper for running commands in tmux

Turn monstrous npm script compositions
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
into terse, sensible tmux layouts
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
tmux-run <sessionname> --layout=1224 --orientation=ltr
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
tmux-run <sessionname> 1224 ltr "cmd a" "cmd b" "cmd c" etc...
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
tmux-run <session-name> \                   # session name required unless --npm set; all other args optional
  [-h|--help] \                             #
  [-n|--npm] \                              # if set, prefix each command with "npm run" for package.json scripts
  [[-l|--layout=]<1-9,[,],{,}>] \           # [default: generated for # of cmds] each digit represents number of panes in column
  [[-o|--orientation=]<ttb|ltr>] \          # [default: ttb (top-to-bottom)] transpose layout if orientation=ltr (left-to-right)
  [[-e|--exists=]<replace|attach|error>] \  # [default: replace] replace, attach, or error when session already exists
  [--extra="tmux cmd A ; tmux cmd B"] \     # extra tmux commands to be executed after window and panes are created
  ["shell command 1"] \                     # shell commands that will be executed in each pane
  ["shell command 2"] \                     #
  ...                                       #
  ["shell command N"]                       # number of shell commands N must not exceed sum of layout
```
