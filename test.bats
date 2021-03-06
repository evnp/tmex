#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

dir=$BATS_TEST_DIRNAME

setup() {
  # ensure TMUX_PANE is not set at beginning of test so that tests can be run
  # from within tmux (TMUX_PANE handling is tested explicitly at end of suite)
  unset TMUX_PANE
}

@test "./tmex --print" {
  run $dir/tmex --print
  assert_output -p "Invalid input: session name required"
  assert_output -p "Usage:"
  assert_failure
}

@test "./tmex -p" {
  run $dir/tmex -p
  assert_output -p "Invalid input: session name required"
  assert_output -p "Usage:"
  assert_failure
}

@test "./tmex testsessionname --print" {
  run $dir/tmex testsessionname --print
  assert_output -p "new-session -s testsessionname"
  assert_success
}

@test "./tmex testsessionname -p" {
  run $dir/tmex testsessionname -p
  assert_output -p "new-session -s testsessionname"
  assert_success
}

@test "./tmex --help" {
  run $dir/tmex --help
  assert_output -p "Usage:"
  assert_success
}

@test "./tmex -h" {
  run $dir/tmex -h
  assert_output -p "Usage:"
  assert_success
}

@test "./tmex --version" {
  run $dir/tmex --version
  assert_output -p "tmex"
  assert_success
}

@test "./tmex -v" {
  run $dir/tmex -v
  assert_output -p "tmex"
  assert_success
}

@test "./tmex --print --npm" {
  export npm_package_name="testpackagename"
  run $dir/tmex --print --npm
  assert_output -p "new-session -s testpackagename"
  assert_success
  unset npm_package_name
}

@test "./tmex -pn" {
  export npm_package_name="testpackagename"
  run $dir/tmex -pn
  assert_output -p "new-session -s testpackagename"
  assert_success
  unset npm_package_name
}

@test "./tmex testsessionname --print --npm" {
  export npm_package_name="testpackagename"
  run $dir/tmex testsessionname --print --npm
  assert_output -p "new-session -s testsessionname"
  assert_success
  unset npm_package_name
}

@test "./tmex testsessionname -pn" {
  export npm_package_name="testpackagename"
  run $dir/tmex testsessionname -pn
  assert_output -p "new-session -s testsessionname"
  assert_success
  unset npm_package_name
}

function print_layout () {
  layout="$1"

  IFS=$';'
  expected=""
  for command in ${layout}; do
    command="${command#"${command%%[![:space:]]*}"}"  # remove leading whitespace
    command="${command%"${command##*[![:space:]]}"}"  # remove trailing whitespace
    command=$( echo "${command}" | tr -s " " )  # replace multiple space with single

    if [[ "${command}" =~ ^(split-window|select-pane|send-keys) ]]; then
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
  suffix=" ; "
  expected="${expected%${suffix}}"  # remove trailing semicolon
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

@test "./tmex testsessionname -p 1234" {
  run $dir/tmex testsessionname -p 1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -p -l1234" {
  run $dir/tmex testsessionname -p -l1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -p -l 1234" {
  run $dir/tmex testsessionname -p -l 1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -l1234 -p" {
  run $dir/tmex testsessionname -l1234 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -l 1234 -p" {
  run $dir/tmex testsessionname -l 1234 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -p --layout=1234" {
  run $dir/tmex testsessionname -p --layout=1234
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_1234}"
  assert_success
}

@test "./tmex testsessionname -p --layout 1234" {
  run $dir/tmex testsessionname -p --layout 1234
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

@test "./tmex testsessionname -pt 1234" {
  run $dir/tmex testsessionname -pt 1234
  assert_layout "${layout_1234_transposed}"
  assert_success
}

@test "./tmex testsessionname -p -l1234 -t" {
  run $dir/tmex testsessionname -p -l1234 -t
  assert_layout "${layout_1234_transposed}"
  assert_success
}

@test "./tmex testsessionname --print --layout=1234 --transpose" {
  run $dir/tmex testsessionname --print --layout=1234 --transpose
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

@test "./tmex testsessionname -p 1[2{34}5]6" {
  run $dir/tmex testsessionname -p 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -p -l1[2{34}5]6" {
  run $dir/tmex testsessionname -p -l1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -p -l 1[2{34}5]6" {
  run $dir/tmex testsessionname -p -l 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -l1[2{34}5]6 -p" {
  run $dir/tmex testsessionname -l1[2{34}5]6 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -l 1[2{34}5]6 -p" {
  run $dir/tmex testsessionname -l 1[2{34}5]6 -p
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -p --layout=1[2{34}5]6" {
  run $dir/tmex testsessionname -p --layout=1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

@test "./tmex testsessionname -p --layout 1[2{34}5]6" {
  run $dir/tmex testsessionname -p --layout 1[2{34}5]6
  assert_output -p "new-session -s testsessionname"
  assert_layout "${layout_123456}"
  assert_success
}

layout_123456_transposed="
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

@test "./tmex testsessionname -pt 1[2{34}5]6" {
  run $dir/tmex testsessionname -pt 1[2{34}5]6
  assert_layout "${layout_123456_transposed}"
  assert_success
}

@test "./tmex testsessionname -p -l1[2{34}5]6 -t" {
  run $dir/tmex testsessionname -p -l1[2{34}5]6 -t
  assert_layout "${layout_123456_transposed}"
  assert_success
}

@test "./tmex testsessionname --print --layout=1[2{34}5]6 --transpose" {
  run $dir/tmex testsessionname --print --layout=1[2{34}5]6 --transpose
  assert_layout "${layout_123456_transposed}"
  assert_success
}

@test "./tmex testsessionname -p --shellless a" {
  run $dir/tmex testsessionname -p --shellless a
  assert_layout ""
  assert_success
}

@test "./tmex testsessionname -p --shellless a b" {
  run $dir/tmex testsessionname -p --shellless a b
  assert_layout "
    split-window -h -p50 b
     select-pane -L
     select-pane -R
  "
  assert_success
}

@test "./tmex testsessionname -p --shellless a b c" {
  run $dir/tmex testsessionname -p --shellless a b c
  assert_layout "
    split-window -h -p50 b
     select-pane -L
     select-pane -R
    split-window -v -p50 c
  "
  assert_success
}

@test "./tmex testsessionname -p --shellless a b c d" {
  run $dir/tmex testsessionname -p --shellless a b c d
  assert_layout "
    split-window -h -p50 c
     select-pane -L
    split-window -v -p50 b
     select-pane -R
    split-window -v -p50 d
  "
  assert_success
}

@test "./tmex testsessionname -p --shellless a b c d e" {
  run $dir/tmex testsessionname -p --shellless a b c d e
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

@test "./tmex testsessionname -p --shellless a b c d e f" {
  run $dir/tmex testsessionname -p --shellless a b c d e f
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

@test "./tmex testsessionname -p --shellless a b c d e f g" {
  run $dir/tmex testsessionname -p --shellless a b c d e f g
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

@test "./tmex testsessionname -p --shellless a b c d e f g h" {
  run $dir/tmex testsessionname -p --shellless a b c d e f g h
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

@test "./tmex testsessionname -p --shellless a b c d e f g h i" {
  run $dir/tmex testsessionname -p --shellless a b c d e f g h i
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

@test "./tmex -p --npm a" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p50
       send-keys \"npm run b\" Enter
     select-pane -L
     select-pane -R
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p50
       send-keys \"npm run b\" Enter
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys \"npm run c\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p50
       send-keys \"npm run c\" Enter
     select-pane -L
    split-window -v -p50
       send-keys \"npm run b\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run d\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d e" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d e
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p67
       send-keys \"npm run b\" Enter
    split-window -h -p50
       send-keys \"npm run d\" Enter
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys \"npm run c\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run e\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d e f" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d e f
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p67
       send-keys \"npm run c\" Enter
    split-window -h -p50
       send-keys \"npm run e\" Enter
     select-pane -L
     select-pane -L
    split-window -v -p50
       send-keys \"npm run b\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run d\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run f\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d e f g" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d e f g
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p50 -d
       send-keys \"npm run d\" Enter
    split-window -h -p50
       send-keys \"npm run b\" Enter
     select-pane -R
    split-window -h -p50
       send-keys \"npm run f\" Enter
     select-pane -L
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys \"npm run c\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run e\" Enter
     select-pane -R
    split-window -v -p50
       send-keys \"npm run g\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d e f g h" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d e f g h
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p67
       send-keys \"npm run c\" Enter
    split-window -h -p50
       send-keys \"npm run f\" Enter
     select-pane -L
     select-pane -L
    split-window -v -p50
       send-keys \"npm run b\" Enter
     select-pane -R
    split-window -v -p67
       send-keys \"npm run d\" Enter
    split-window -v -p50
       send-keys \"npm run e\" Enter
     select-pane -R
    split-window -v -p67
       send-keys \"npm run g\" Enter
    split-window -v -p50
       send-keys \"npm run h\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -p --npm a b c d e f g h i" {
  export npm_package_name="testpackagename"
  run $dir/tmex -p --npm a b c d e f g h i
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p67
       send-keys \"npm run d\" Enter
    split-window -h -p50
       send-keys \"npm run g\" Enter
     select-pane -L
     select-pane -L
    split-window -v -p67
       send-keys \"npm run b\" Enter
    split-window -v -p50
       send-keys \"npm run c\" Enter
     select-pane -R
    split-window -v -p67
       send-keys \"npm run e\" Enter
    split-window -v -p50
       send-keys \"npm run f\" Enter
     select-pane -R
    split-window -v -p67
       send-keys \"npm run h\" Enter
    split-window -v -p50
       send-keys \"npm run i\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -pn 1234 a b c d e f g h i j" {
  export npm_package_name="testpackagename"
  run $dir/tmex -pn 1234 a b c d e f g h i j
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p50 -d
       send-keys \"npm run d\" Enter
    split-window -h -p50
       send-keys \"npm run b\" Enter
     select-pane -R
    split-window -h -p50
       send-keys \"npm run g\" Enter
     select-pane -L
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys \"npm run c\" Enter
     select-pane -R
    split-window -v -p67
       send-keys \"npm run e\" Enter
    split-window -v -p50
       send-keys \"npm run f\" Enter
     select-pane -R
    split-window -v -p50 -d
       send-keys \"npm run i\" Enter
    split-window -v -p50
       send-keys \"npm run h\" Enter
     select-pane -D
    split-window -v -p50
       send-keys \"npm run j\" Enter
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -pn 1[2{34}5]6 a b c d e f g h i j" {
  export npm_package_name="testpackagename"
  run $dir/tmex -pn 1[2{34}5]6 a b c d e f g h i j
  assert_output -p "new-session -s testpackagename"
  assert_layout "
       send-keys \"npm run a\" Enter
    split-window -h -p67
       send-keys \"npm run b\" Enter
    split-window -h -p50
       send-keys \"npm run i\" Enter
     select-pane -L
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys \"npm run d\" Enter
     select-pane -U
    split-window -h -p57
       send-keys \"npm run c\" Enter
     select-pane -D
    split-window -h -p80
       send-keys \"npm run e\" Enter
    split-window -h -p50 -d
       send-keys \"npm run g\" Enter
    split-window -h -p50
       send-keys \"npm run f\" Enter
     select-pane -R
    split-window -h -p50
       send-keys \"npm run h\" Enter
     select-pane -R
    split-window -v -p50 -d
    split-window -v -p67
       send-keys \"npm run j\" Enter
    split-window -v -p50
     select-pane -D
    split-window -v -p67
    split-window -v -p50
  "
  assert_success
  unset npm_package_name
}

@test "./tmex -pn 1234 a b c d e f g h i j k" {
  run $dir/tmex -pn 1234 a b c d e f g h i j k
  assert_output -p "Invalid input: --layout=1234 is too small for number of commands provided"
}

@test "./tmex -pn 1[2{34}5]6 a b c d e f g h i j k l m n o" {
  run $dir/tmex -pn 1[2{34}5]6 a b c d e f g h i j k l m n o
  assert_output -p "Invalid input: --layout=1[2{34}5]6 is too small for number of commands provided"
}

# ensure nested tmex commands will select and split their current pane
# instead of spawning a nested tmux session
@test "TMUX_PANE=%5 ./tmex testsessionname -p a b c" {
  export TMUX_PANE="%5"
  run $dir/tmex testsessionname -p a b c
  refute_output -p "new-session -s testsessionname"
  assert_output -p "select-window -t %5 ; select-pane -t %5"
  assert_layout "
       send-keys a Enter
    split-window -h -p50
       send-keys b Enter
     select-pane -L
     select-pane -R
    split-window -v -p50
       send-keys c Enter
  "
  assert_success
  unset TMUX_PANE
}
