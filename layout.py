#!/usr/bin/env python3

import re
import sys

_, session, layout, *commands = sys.argv
numcols = layout and len(layout) or 0

layout = layout.lower()
if numcols < 1 or not re.match(r'[1-9]+(ltr|ttb)?', layout):
    raise ValueError('invalid layout')
ltr = layout.endswith('ltr')
layout = re.sub(r'\D', '', layout)


def split(commands, direction):
    if direction not in ['v', 'h']:
        raise ValueError('invalid direction')
    if len(commands) < 2:
        return []
    elif len(commands) == 2:
        return ['split-window -{} "{}"'.format(direction, commands[1])]
    elif len(commands) % 2:
        percentage = 100 - round(100 / len(commands))
        return (
          ['split-window -{} -p{} "{}"'.format(
              direction,
              percentage,
              commands[1],
          )] + split(commands[1:], direction)
        )
    else:
        selectpane = 'select-pane -{}'.format('D' if direction == 'v' else 'R')
        firsthalf = commands[:int(len(commands) / 2)]
        secondhalf = commands[int(len(commands) / 2):]
        return (
          ['split-window -{} -d "{}"'.format(direction, secondhalf[0])] +
          split(firsthalf, direction) +
          [selectpane] +
          split(secondhalf, direction)
        )


rowcommands = []
colsum = 0

for col in layout:
    rowcommands.append(commands[colsum])
    colsum += int(col)

tmux = ['tmux new-session -s {} "{}"'.format(session, commands[0])]
tmux += split(rowcommands, 'v' if ltr else 'h')
tmux += ['select-pane -{}'.format('U' if ltr else 'L') for _ in range(len(layout) - 1)]  # back to 1st col

colcommmands = []
colsum = 0

for i, col in enumerate(layout):
    colcommands = commands[colsum:(colsum + int(col))]
    tmux += split(colcommands, 'h' if ltr else 'v')
    colsum += int(col)
    if i < len(layout) - 1:
        tmux += ['select-pane -{}'.format('D' if ltr else 'R')]

print(' \\; '.join(tmux))
