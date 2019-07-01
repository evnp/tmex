#!/usr/bin/env python3

import json
import re
import sys


# construct a partial tmux command that splits a pane appropriately to execute
# provided commands (excluding 1st command, which is run in 1st split of pane)
def split(commands, direction):
    if direction not in ['v', 'h']:
        raise ValueError('invalid direction')
    if len(commands) < 2:
        return []
    elif len(commands) == 2:
        return ['split-window -{} "{}"'.format(
            direction, commands[1],
        )]
    elif len(commands) % 2:
        percentage = 100 - round(100 / len(commands))
        return (
            ['split-window -{} -p{} "{}"'.format(
                direction, percentage, commands[1],
            )] +
            split(commands[1:], direction)
        )
    else:
        selectpane = 'select-pane -{}'.format(
            'D' if direction == 'v' else 'R',
        )
        firsthalf = commands[:int(len(commands) / 2)]
        secondhalf = commands[int(len(commands) / 2):]
        return (
          ['split-window -{} -d "{}"'.format(
              direction, secondhalf[0],
          )] +
          split(firsthalf, direction) +
          [selectpane] +
          split(secondhalf, direction)
        )


if __name__ == "__main__":
    # parse args
    _, session, options, layout, orientation, *commands = sys.argv

    # pad commands so that layout is filled -
    # blank commands will result in tmux pane running blank shell
    commands += [''] * (sum(map(int, layout)) - len(commands))

    # convenience func
    def orient(chars):
        return chars[0] if orientation == 'ltr' else chars[1]

    tmux = ['tmux new-session -s {} "{}"'.format(
        session, commands[0],
    )]
    topcmd = []
    colsum = 0

    # construct initial set of column panes (or rows if orientation="ltr")
    for col in layout:
        topcmd.append(commands[colsum])
        colsum += int(col)
    tmux += split(topcmd, orient('vh'))

    # select 1st col pane
    tmux += ['select-pane -{}'.format(orient('UL'))] * (len(layout) - 1)

    colcmd = []
    colsum = 0

    # split each column pane (or row if orientation="ltr") into multiple panes
    for i, col in enumerate(layout):
        colcmd = commands[colsum:(colsum + int(col))]
        tmux += split(colcmd, orient('hv'))
        colsum += int(col)
        if i < len(layout) - 1:
            tmux += ['select-pane -{}'.format(orient('DR'))]

    # handle customizable json obj of tmux window options
    if options and len(options):
        try:
            options = json.loads(options)
        except json.decoder.JSONDecodeError as e:
            print('JSONDecodeError: {}'.format(e))
            sys.exit(1)

    for option, value in options.items():
        tmux += ['set-window-option {} {}'.format(
            option, value,
        )]

    print(' \\; '.join(tmux))
    sys.exit(0)
