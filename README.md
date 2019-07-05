tmux-run
========
A minimalist layout wrapper for running commands in tmux

Turn monstrous npm script compositions
```
package.json
{
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
into beautiful tmux layouts
```
package.json
{
  "scripts": {
    ..
    "watch": "parcel index.html",
    "server": "python -m http.server",
    "typecheck" "tsc --watch --noEmit",
    "start": "tmux-run $npm_package_name 'npm run watch' 'npm run server' 'npm run typecheck'",
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
```

Passed 8 commands, tmux-run generates this layout:
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
tmux-run buildsession --layout=1224
>>>
+-----+-----+-----+-----+
|     |     |     |     |
|     |     |     +-----+
|     |     |     |     |
|     +-----+-----+-----+
|     |     |     |     |
|     |     |     +-----+
|     |     |     |     |
+-----+-----+-----+-----+
```

Left-to-right layout instead of top-to-bottom:
```
tmux-run buildsession --layout=1224 --orientation=ltr
>>>
+-----------------------+
|                       |
|-----------+-----------+
|           |           |
|-----------+-----------+
|           |           |
|-----+-----+-----+-----+
|     |     |     |     |
+-----+-----+-----+-----+
```

Shorthand:
```
tmux-run buildsession 1224 ltr "cmd a" "cmd b" "cmd c" etc...
```

Full options list (also accessible via `tmux-run --help`):
```
tmux-run <session-name> \
  [-h|--help] \
  [[-l|--layout=]{integer}] \             # [default: generated to match number of commands provided] each digit represents number of panes in column
  [[-o|--orientation=]ttb|ltr] \          # [default: ttb (top-to-bottom)] transpose layout if orientation=ltr (left-to-right)
  [[-e|--exists=]replace|attach|error] \  # [default: replace] exists when session already exists
  [--extra="tmux cmd A ; tmux cmd B"] \   # extra tmux commands to be executed after window and panes are created
  ["shell command 1"] \                   # shell commands that will be executed in each pane
  ["shell command 2"] \
  ...
  ["shell command N"]                     # number of shell commands N must not exceed sum of layout
```
