#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

dir=$BATS_TEST_DIRNAME

@test "./tmux-run --print" {
  run $dir/tmux-run --print
  assert_output -p "Invalid input: session name required"
  assert_output -p "Usage:"
  assert_failure
}

@test "./tmux-run -p" {
  run $dir/tmux-run -p
  assert_output -p "Invalid input: session name required"
  assert_output -p "Usage:"
  assert_failure
}

@test "./tmux-run testsessionname --print" {
  run $dir/tmux-run testsessionname --print
  assert_output -p "new-session -s testsessionname"
  assert_success
}

@test "./tmux-run testsessionname -p" {
  run $dir/tmux-run testsessionname -p
  assert_output -p "new-session -s testsessionname"
  assert_success
}

@test "./tmux-run --help" {
  run $dir/tmux-run --help
  assert_output -p "Usage:"
  assert_success
}

@test "./tmux-run -h" {
  run $dir/tmux-run -h
  assert_output -p "Usage:"
  assert_success
}

@test "./tmux-run --version" {
  run $dir/tmux-run --version
  assert_output -p "tmux-run"
  assert_success
}

@test "./tmux-run -v" {
  run $dir/tmux-run -v
  assert_output -p "tmux-run"
  assert_success
}

@test "./tmux-run --print --npm" {
  npm_package_name="testpackagename"
  run $dir/tmux-run --print --npm
  assert_output -p "new-session -s testpackagename"
  assert_success
}

@test "./tmux-run -pn" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -pn
  assert_output -p "new-session -s testpackagename"
  assert_success
}

@test "./tmux-run testsessionname --print --npm" {
  npm_package_name="testpackagename"
  run $dir/tmux-run testsessionname --print --npm
  assert_output -p "new-session -s testsessionname"
  assert_success
}

@test "./tmux-run testsessionname -pn" {
  npm_package_name="testpackagename"
  run $dir/tmux-run testsessionname -pn
  assert_output -p "new-session -s testsessionname"
  assert_success
}

function print_layout () {
  layout="$1"

  IFS=$';'
  expected=""
  for command in ${layout}; do
    command="${command#"${command%%[![:space:]]*}"}"  # remove leading whitespace
    command="${command%"${command##*[![:space:]]}"}"  # remove trailing whitespace
    command=$( echo "${command}" | tr -s " " )  # replace multiple space with single

    if [[ "${command}" =~ ^(split-window|select-pane) ]]; then
      expected+="${command}
"
    fi
  done
  unset IFS

  echo "${expected}"
}

function assert_layout () {
  local layout
  local command
  local expected

  layout="$1"

  IFS=$'\n'
  expected=""
  for command in ${layout}; do
    command="${command#"${command%%[![:space:]]*}"}"  # remove leading whitespace
    command="${command%"${command##*[![:space:]]}"}"  # remove trailing whitespace
    command=$( echo "${command}" | tr -s " " )  # replace multiple space with single
    if [[ -n "${command}" ]]; then
      expected+="${command} ; "
    fi
  done
  unset IFS

  assert_output -p "${expected}"
}

layout_1234="
  split-window -h -p50 -d
  split-window -h -p50
   select-pane -R
  split-window -h -p50
   select-pane -L
   select-pane -L
   select-pane -L
   select-pane -R
  split-window -v -p50
   select-pane -R
  split-window -v -p67
  split-window -v -p50
   select-pane -R
  split-window -v -p50 -d
  split-window -v -p50
   select-pane -D
  split-window -v -p50
"

@test "./tmux-run testsessionname -p 1234" {
  run $dir/tmux-run testsessionname -p 1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -p -l1234" {
  run $dir/tmux-run testsessionname -p -l1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -p -l 1234" {
  run $dir/tmux-run testsessionname -p -l 1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -l1234 -p" {
  run $dir/tmux-run testsessionname -l1234 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -l 1234 -p" {
  run $dir/tmux-run testsessionname -l 1234 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -p --layout=1234" {
  run $dir/tmux-run testsessionname -p --layout=1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmux-run testsessionname -p --layout 1234" {
  run $dir/tmux-run testsessionname -p --layout 1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

layout_1234_transposed="
  split-window -v -p50 -d
  split-window -v -p50
   select-pane -D
  split-window -v -p50
   select-pane -U
   select-pane -U
   select-pane -U
   select-pane -D
  split-window -h -p50
   select-pane -D
  split-window -h -p67
  split-window -h -p50
   select-pane -D
  split-window -h -p50 -d
  split-window -h -p50
   select-pane -R
  split-window -h -p50
"

@test "./tmux-run testsessionname -pt 1234" {
  run $dir/tmux-run testsessionname -pt 1234
  assert_layout "${layout_1234_transposed}"
  assert_success
}

@test "./tmux-run testsessionname -p -l1234 -t" {
  run $dir/tmux-run testsessionname -p -l1234 -t
  assert_layout "${layout_1234_transposed}"
  assert_success
}

@test "./tmux-run testsessionname --print --layout=1234 --transpose" {
  run $dir/tmux-run testsessionname --print --layout=1234 --transpose
  assert_layout "${layout_1234_transposed}"
  assert_success
}

layout_123456="
  split-window -h -p67
  split-window -h -p50
   select-pane -L
   select-pane -L
   select-pane -R
  split-window -v -p50
   select-pane -U
  split-window -h -p57
   select-pane -D
  split-window -h -p80
  split-window -h -p50 -d
  split-window -h -p50
   select-pane -R
  split-window -h -p50
   select-pane -R
  split-window -v -p50 -d
  split-window -v -p67
  split-window -v -p50
   select-pane -D
  split-window -v -p67
  split-window -v -p50
"

@test "./tmux-run testsessionname -p 1[2{34}5]6" {
  run $dir/tmux-run testsessionname -p 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -p -l1[2{34}5]6" {
  run $dir/tmux-run testsessionname -p -l1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -p -l 1[2{34}5]6" {
  run $dir/tmux-run testsessionname -p -l 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -l1[2{34}5]6 -p" {
  run $dir/tmux-run testsessionname -l1[2{34}5]6 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -l 1[2{34}5]6 -p" {
  run $dir/tmux-run testsessionname -l 1[2{34}5]6 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -p --layout=1[2{34}5]6" {
  run $dir/tmux-run testsessionname -p --layout=1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmux-run testsessionname -p --layout 1[2{34}5]6" {
  run $dir/tmux-run testsessionname -p --layout 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

layout_123456_ltr="
  split-window -v -p67
  split-window -v -p50
   select-pane -U
   select-pane -U
   select-pane -D
  split-window -h -p50
   select-pane -L
  split-window -v -p57
   select-pane -R
  split-window -v -p80
  split-window -v -p50 -d
  split-window -v -p50
   select-pane -D
  split-window -v -p50
   select-pane -D
  split-window -h -p50 -d
  split-window -h -p67
  split-window -h -p50
   select-pane -R
  split-window -h -p67
  split-window -h -p50
"

@test "./tmux-run testsessionname -pt 1[2{34}5]6" {
  run $dir/tmux-run testsessionname -pt 1[2{34}5]6
  assert_layout "${layout_123456_ltr}"
  assert_success
}

@test "./tmux-run testsessionname -p -l1[2{34}5]6 -t" {
  run $dir/tmux-run testsessionname -p -l1[2{34}5]6 -t
  assert_layout "${layout_123456_ltr}"
  assert_success
}

@test "./tmux-run testsessionname --print --layout=1[2{34}5]6 --transpose" {
  run $dir/tmux-run testsessionname --print --layout=1[2{34}5]6 --transpose
  assert_layout "${layout_123456_ltr}"
  assert_success
}

@test "./tmux-run testsessionname -p a" {
  run $dir/tmux-run testsessionname -p a
  assert_layout ""
  assert_success
}

@test "./tmux-run testsessionname -p a b" {
  run $dir/tmux-run testsessionname -p a b
  assert_layout "
    split-window -h -p50 b
     select-pane -L
     select-pane -R
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c" {
  run $dir/tmux-run testsessionname -p a b c
  assert_layout "
    split-window -h -p50 b
     select-pane -L
     select-pane -R
    split-window -v -p50 c
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d" {
  run $dir/tmux-run testsessionname -p a b c d
  assert_layout "
    split-window -h -p50 c
     select-pane -L
    split-window -v -p50 b
     select-pane -R
    split-window -v -p50 d
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d e" {
  run $dir/tmux-run testsessionname -p a b c d e
  assert_layout "
    split-window -h -p67 b
    split-window -h -p50 d
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50 c
     select-pane -R
    split-window -v -p50 e
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d e f" {
  run $dir/tmux-run testsessionname -p a b c d e f
  assert_layout "
    split-window -h -p67 c
    split-window -h -p50 e
     select-pane -L
     select-pane -L
    split-window -v -p50 b
     select-pane -R
    split-window -v -p50 d
     select-pane -R
    split-window -v -p50 f
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d e f g" {
  run $dir/tmux-run testsessionname -p a b c d e f g
  assert_layout "
    split-window -h -p50 -d d
    split-window -h -p50 b
    select-pane -R
    split-window -h -p50 f
    select-pane -L
    select-pane -L
    select-pane -L
    select-pane -R
    split-window -v -p50 c
    select-pane -R
    split-window -v -p50 e
    select-pane -R
    split-window -v -p50 g
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d e f g h" {
  run $dir/tmux-run testsessionname -p a b c d e f g h
  assert_layout "
    split-window -h -p67 c
    split-window -h -p50 f
    select-pane -L
    select-pane -L
    split-window -v -p50 b
    select-pane -R
    split-window -v -p67 d
    split-window -v -p50 e
    select-pane -R
    split-window -v -p67 g
    split-window -v -p50 h
  "
  assert_success
}

@test "./tmux-run testsessionname -p a b c d e f g h i" {
  run $dir/tmux-run testsessionname -p a b c d e f g h i
  assert_layout "
    split-window -h -p67 d
    split-window -h -p50 g
    select-pane -L
    select-pane -L
    split-window -v -p67 b
    split-window -v -p50 c
    select-pane -R
    split-window -v -p67 e
    split-window -v -p50 f
    select-pane -R
    split-window -v -p67 h
    split-window -v -p50 i
  "
  assert_success
}

@test "./tmux-run -p --npm a" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a
  assert_output -p "new-session -s testpackagename"
  assert_layout ""
  assert_success
}

@test "./tmux-run -p --npm a b" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p50 \"npm run b\"
     select-pane -L
     select-pane -R
  "
  assert_success
}

@test "./tmux-run -p --npm a b c" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p50 \"npm run b\"
     select-pane -L
     select-pane -R
    split-window -v -p50 \"npm run c\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p50 \"npm run c\"
     select-pane -L
    split-window -v -p50 \"npm run b\"
     select-pane -R
    split-window -v -p50 \"npm run d\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d e" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d e
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p67 \"npm run b\"
    split-window -h -p50 \"npm run d\"
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50 \"npm run c\"
     select-pane -R
    split-window -v -p50 \"npm run e\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d e f" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d e f
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p67 \"npm run c\"
    split-window -h -p50 \"npm run e\"
     select-pane -L
     select-pane -L
    split-window -v -p50 \"npm run b\"
     select-pane -R
    split-window -v -p50 \"npm run d\"
     select-pane -R
    split-window -v -p50 \"npm run f\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d e f g" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d e f g
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p50 -d \"npm run d\"
    split-window -h -p50 \"npm run b\"
    select-pane -R
    split-window -h -p50 \"npm run f\"
    select-pane -L
    select-pane -L
    select-pane -L
    select-pane -R
    split-window -v -p50 \"npm run c\"
    select-pane -R
    split-window -v -p50 \"npm run e\"
    select-pane -R
    split-window -v -p50 \"npm run g\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d e f g h" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d e f g h
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p67 \"npm run c\"
    split-window -h -p50 \"npm run f\"
    select-pane -L
    select-pane -L
    split-window -v -p50 \"npm run b\"
    select-pane -R
    split-window -v -p67 \"npm run d\"
    split-window -v -p50 \"npm run e\"
    select-pane -R
    split-window -v -p67 \"npm run g\"
    split-window -v -p50 \"npm run h\"
  "
  assert_success
}

@test "./tmux-run -p --npm a b c d e f g h i" {
  npm_package_name="testpackagename"
  run $dir/tmux-run -p --npm a b c d e f g h i
  assert_output -p "new-session -s testpackagename"
  assert_layout "
    split-window -h -p67 \"npm run d\"
    split-window -h -p50 \"npm run g\"
    select-pane -L
    select-pane -L
    split-window -v -p67 \"npm run b\"
    split-window -v -p50 \"npm run c\"
    select-pane -R
    split-window -v -p67 \"npm run e\"
    split-window -v -p50 \"npm run f\"
    select-pane -R
    split-window -v -p67 \"npm run h\"
    split-window -v -p50 \"npm run i\"
  "
  assert_success
}
