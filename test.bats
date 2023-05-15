#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

dir=$BATS_TEST_DIRNAME

ORIGINAL_PATH="$PATH"

setup() {
	# ensure TMUX_PANE is not set at beginning of test so that tests can be run
	# from within tmux (TMUX_PANE handling is tested explicitly at end of suite)
	unset TMUX_PANE
  export TMUX_VERSION="3.0"
	mock_tmux
}

teardown() {
	unset TMUX_PANE
	unset TMUX_VERSION
	restore_tmux
}

mock_tmux() {
	mkdir testbin
	export PATH="./testbin:$PATH"
	cat <<-EOF > ./testbin/tmux
		#!/usr/bin/env bash
		main() {
			local args
			local arg
			local output=""
			if [[ "\$*" == '-V' ]]; then
				echo "tmux \${TMUX_VERSION}"
				exit 0
			fi
			args=( "\$@" )
			for (( idx = 0; idx < \${#args[@]}; idx++ )); do
				arg="\${args[idx]}"
				if [[ "\${args[idx]}" =~ [[:space:]] ]]; then
					arg="\${arg//\\"/\\\\\\"}"
					output+="\\"\${arg}\\" "
				else
					output+="\${arg} "
				fi
			done
			echo "\${output}"
		}
		main "\${@}"
	EOF
	chmod +x ./testbin/tmux
}

restore_tmux() {
	rm -rf testbin
	export PATH="$ORIGINAL_PATH"
}

@test "./tmex" {
	run $dir/tmex
	assert_output -p "Invalid input: session name required"
	assert_output -p "Usage:"
	assert_failure
}

@test "./tmex testsessionname" {
	run $dir/tmex testsessionname
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

@test "./tmex --npm" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm
	assert_output -p "new-session -s testpackagename"
	assert_success
	unset npm_package_name
}

@test "./tmex -n" {
	export npm_package_name="testpackagename"
	run $dir/tmex -n
	assert_output -p "new-session -s testpackagename"
	assert_success
	unset npm_package_name
}

@test "./tmex testsessionname --npm" {
	export npm_package_name="testpackagename"
	run $dir/tmex testsessionname --npm
	assert_output -p "new-session -s testsessionname"
	assert_success
	unset npm_package_name
}

@test "./tmex testsessionname -n" {
	export npm_package_name="testpackagename"
	run $dir/tmex testsessionname -n
	assert_output -p "new-session -s testsessionname"
	assert_success
	unset npm_package_name
}

function print_layout () {
	layout="$1"

	IFS=$';'
	expected=""
	for command in ${layout}; do
		command="${command#"${command%%[![:space:]]*}"}"	# remove leading whitespace
		command="${command%"${command##*[![:space:]]}"}"	# remove trailing whitespace
		command=$( echo "${command}" | tr -s " " )	# replace multiple space with single

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
		command="${command#"${command%%[![:space:]]*}"}"	# remove leading whitespace
		command="${command%"${command##*[![:space:]]}"}"	# remove trailing whitespace
		command=$( echo "${command}" | tr -s " " )	# replace multiple space with single
		if [[ -n "${command}" ]]; then
			expected+="${command} ; "
		fi
	done
	suffix=" ; "
	expected="${expected%"${suffix}"}"	# remove trailing semicolon
	unset IFS

	assert_output -p "${expected}"
}

function refute_layout () {
  ! assert_layout "$@"
}

function assert_layout_shorthand() {
	assert_layout "$(
		xargs <<< "$1" |
		sed -E 's/H/; split-window -h/g' |
		sed -E 's/V/; split-window -v/g' |
		sed -E 's/(U|D|L|R)/; select-pane -\1/g'
	)"
}

layout_1234="
	split-window -h -p50
	 select-pane -L
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
	split-window -v -p50
	 select-pane -U
	split-window -v -p50
	 select-pane -D
	split-window -v -p50
"

@test "./tmex testsessionname 1234" {
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname -l1234" {
	run $dir/tmex testsessionname -l1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname -l 1234" {
	run $dir/tmex testsessionname -l 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname --layout=1234" {
	run $dir/tmex testsessionname --layout=1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname --layout 1234" {
	run $dir/tmex testsessionname --layout 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname --layout {1111}1234" {
	run $dir/tmex testsessionname --layout {1111}1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "./tmex testsessionname --layout {9999}1234" {
	run $dir/tmex testsessionname --layout {9999}1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

layout_4321="
	split-window -h -p30
	 select-pane -L
	split-window -h -p43
	 select-pane -R
	split-window -h -p33
	 select-pane -L
	 select-pane -L
	 select-pane -L
	 select-pane -R
	split-window -v -p50
	 select-pane -R
	split-window -v -p67
	split-window -v -p50
	 select-pane -R
	split-window -v -p50
	 select-pane -U
	split-window -v -p50
	 select-pane -D
	split-window -v -p50
"

@test "./tmex testsessionname --layout {4321}1234" {
	run $dir/tmex testsessionname --layout {4321}1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}

shorthand_layout_987654321="
	H -p80 H -p28 L H -p42 L H -p47 R H -p45 R H -p30 L H -p43 R H -p33
	L L L L L L L L R V -p50 R V -p67 V -p50 R V -p50 U V -p50 D V -p50
	R V -p80 V -p50 U V -p50 D V -p50 R V -p50 U V -p67 V -p50 D V -p67
	V -p50 R V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 R V -p50 U V -p50
	U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 R V -p89 V -p50 U V -p50
	U V -p50 D V -p50 D V -p50 U V -p50 D V -p50
"

@test "./tmex testsessionname --layout {987654321}123456789" {
	run $dir/tmex testsessionname --layout {987654321}123456789
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_987654321}"
	assert_success
}

@test "./tmex testsessionname --layout 3{}34" {
	run $dir/tmex testsessionname --layout 3{}34
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
	run $dir/tmex testsessionname --layout 3{g}34
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
	run $dir/tmex testsessionname --layout 3{grid}34
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
	run $dir/tmex testsessionname --layout 3{G}34
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
	run $dir/tmex testsessionname --layout 3{GRID}34
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

layout_grid5="
	split-window -h -p67
	split-window -h -p50
	 select-pane -L
	 select-pane -L
	split-window -v -p67
	split-window -v -p50
	 select-pane -R
	split-window -v -p67
	split-window -v -p50
	 select-pane -U
	 select-pane -U
	 select-pane -D
	split-window -h -p50
	 select-pane -D
	split-window -h -p50
	 select-pane -R
	split-window -v -p50
	 select-pane -U
	split-window -v -p50
	 select-pane -D
	split-window -v -p50
"

@test "./tmex testsessionname --layout 3[5{}]4" {
	run $dir/tmex testsessionname --layout 3[5{}]4
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
	run $dir/tmex testsessionname --layout 3[5{g}]4
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
	run $dir/tmex testsessionname --layout 3[5{grid}]4
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
	run $dir/tmex testsessionname --layout 3[5{G}]4
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
	run $dir/tmex testsessionname --layout 3[5{GRID}]4
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}

layout_1234_transposed="
	split-window -v -p50
	 select-pane -U
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
	split-window -h -p50
	 select-pane -L
	split-window -h -p50
	 select-pane -R
	split-window -h -p50
"

@test "./tmex testsessionname -t 1234" {
	run $dir/tmex testsessionname -t 1234
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "./tmex testsessionname -l1234 -t" {
	run $dir/tmex testsessionname -l1234 -t
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "./tmex testsessionname --layout=1234 --transpose" {
	run $dir/tmex testsessionname --layout=1234 --transpose
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
	split-window -h -p50
	 select-pane -L
	split-window -h -p50
	 select-pane -R
	split-window -h -p50
	 select-pane -R
	split-window -v -p50
	 select-pane -U
	split-window -v -p67
	split-window -v -p50
	 select-pane -D
	split-window -v -p67
	split-window -v -p50
"

@test "./tmex testsessionname 1[2{34}5]6" {
	run $dir/tmex testsessionname 1[2{34}5]6
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "./tmex testsessionname -l1[2{34}5]6" {
	run $dir/tmex testsessionname -l1[2{34}5]6
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "./tmex testsessionname -l 1[2{34}5]6" {
	run $dir/tmex testsessionname -l 1[2{34}5]6
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "./tmex testsessionname --layout=1[2{34}5]6" {
	run $dir/tmex testsessionname --layout=1[2{34}5]6
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "./tmex testsessionname --layout 1[2{34}5]6" {
	run $dir/tmex testsessionname --layout 1[2{34}5]6
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
	split-window -v -p50
	 select-pane -U
	split-window -v -p50
	 select-pane -D
	split-window -v -p50
	 select-pane -D
	split-window -h -p50
	 select-pane -L
	split-window -h -p67
	split-window -h -p50
	 select-pane -R
	split-window -h -p67
	split-window -h -p50
"

@test "./tmex testsessionname -t 1[2{34}5]6" {
	run $dir/tmex testsessionname -t 1[2{34}5]6
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "./tmex testsessionname -l1[2{34}5]6 -t" {
	run $dir/tmex testsessionname -l1[2{34}5]6 -t
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "./tmex testsessionname --layout=1[2{34}5]6 --transpose" {
	run $dir/tmex testsessionname --layout=1[2{34}5]6 --transpose
	assert_layout "${layout_123456_transposed}"
	assert_success
}

layout_44="
	 send-keys a Enter
split-window -h -p50
	 send-keys e Enter
 select-pane -L
split-window -v -p50
	 send-keys c Enter
 select-pane -U
split-window -v -p50
	 send-keys b Enter
 select-pane -D
split-window -v -p50
	 send-keys d Enter
 select-pane -R
split-window -v -p50
	 send-keys g Enter
 select-pane -U
split-window -v -p50
	 send-keys f Enter
 select-pane -D
split-window -v -p50
	 send-keys h Enter
"

@test "./tmex testsessionname -l=44 a b c d e f g h" {
	run $dir/tmex testsessionname -l=44 a b c d e f g h
	assert_layout "${layout_44}"
	assert_success
}

layout_444="
	 send-keys a Enter
split-window -h -p67
	 send-keys e Enter
split-window -h -p50
	 send-keys i Enter
 select-pane -L
 select-pane -L
split-window -v -p50
	 send-keys c Enter
 select-pane -U
split-window -v -p50
	 send-keys b Enter
 select-pane -D
split-window -v -p50
	 send-keys d Enter
 select-pane -R
split-window -v -p50
	 send-keys g Enter
 select-pane -U
split-window -v -p50
	 send-keys f Enter
 select-pane -D
split-window -v -p50
	 send-keys h Enter
 select-pane -R
split-window -v -p50
	 send-keys k Enter
 select-pane -U
split-window -v -p50
	 send-keys j Enter
 select-pane -D
split-window -v -p50
	 send-keys l Enter
"

@test "./tmex testsessionname -l=444 a b c d e f g h i j k l" {
	run $dir/tmex testsessionname -l=444 a b c d e f g h i j k l
	assert_layout "${layout_444}"
	assert_success
}

# Test Shell-less mode:

@test "./tmex testsessionname --shellless a" {
	run $dir/tmex testsessionname --shellless a
	assert_layout ""
	assert_success
}

@test "./tmex testsessionname --shellless a b" {
	run $dir/tmex testsessionname --shellless a b
	assert_layout "
		split-window -h -p50 b
		 select-pane -L
		 select-pane -R
	"
	assert_success
}

@test "./tmex testsessionname --shellless a b c" {
	run $dir/tmex testsessionname --shellless a b c
	assert_layout "
		split-window -h -p50 b
		 select-pane -L
		 select-pane -R
		split-window -v -p50 c
	"
	assert_success
}

@test "./tmex testsessionname --shellless a b c d" {
	run $dir/tmex testsessionname --shellless a b c d
	assert_layout "
		split-window -h -p50 c
		 select-pane -L
		split-window -v -p50 b
		 select-pane -R
		split-window -v -p50 d
	"
	assert_success
}

@test "./tmex testsessionname --shellless a b c d e" {
	run $dir/tmex testsessionname --shellless a b c d e
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

@test "./tmex testsessionname --shellless a b c d e f" {
	run $dir/tmex testsessionname --shellless a b c d e f
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

@test "./tmex testsessionname --shellless a b c d e f g" {
	run $dir/tmex testsessionname --shellless a b c d e f g
	assert_layout "
		split-window -h -p50 d
		 select-pane -L
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

@test "./tmex testsessionname --shellless a b c d e f g h" {
	run $dir/tmex testsessionname --shellless a b c d e f g h
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

@test "./tmex testsessionname --shellless a b c d e f g h i" {
	run $dir/tmex testsessionname --shellless a b c d e f g h i
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

@test "./tmex --npm a" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a
	assert_output -p "new-session -s testpackagename"
	assert_layout "
			 send-keys \"npm run a\" Enter
	"
	assert_success
	unset npm_package_name
}

@test "./tmex --npm a b" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b
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

@test "./tmex --npm a b c" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c
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

@test "./tmex --npm a b c d" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d
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

@test "./tmex --npm a b c d e" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d e
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

@test "./tmex --npm a b c d e f" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d e f
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

@test "./tmex --npm a b c d e f g" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d e f g
	assert_output -p "new-session -s testpackagename"
	assert_layout "
			 send-keys \"npm run a\" Enter
		split-window -h -p50
			 send-keys \"npm run d\" Enter
		 select-pane -L
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

@test "./tmex --npm a b c d e f g h" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d e f g h
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

@test "./tmex --npm a b c d e f g h i" {
	export npm_package_name="testpackagename"
	run $dir/tmex --npm a b c d e f g h i
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

layout_a_j="
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
	split-window -h -p50
		 send-keys \"npm run g\" Enter
	 select-pane -L
	split-window -h -p50
		 send-keys \"npm run f\" Enter
	 select-pane -R
	split-window -h -p50
		 send-keys \"npm run h\" Enter
	 select-pane -R
	split-window -v -p50
	 select-pane -U
	split-window -v -p67
		 send-keys \"npm run j\" Enter
	split-window -v -p50
	 select-pane -D
	split-window -v -p67
	split-window -v -p50
"

@test "./tmex -n 1234 a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run $dir/tmex -n 1234 a b c d e f g h i j
	assert_output -p "new-session -s testpackagename"
	assert_layout "
			 send-keys \"npm run a\" Enter
		split-window -h -p50
			 send-keys \"npm run d\" Enter
		 select-pane -L
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
		split-window -v -p50
			 send-keys \"npm run i\" Enter
		 select-pane -U
		split-window -v -p50
			 send-keys \"npm run h\" Enter
		 select-pane -D
		split-window -v -p50
			 send-keys \"npm run j\" Enter
	"
	assert_success
	unset npm_package_name
}

@test "./tmex -n 1[2{34}5]6 a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run $dir/tmex -n 1[2{34}5]6 a b c d e f g h i j
	assert_output -p "new-session -s testpackagename"
	assert_layout "${layout_a_j}"
	assert_success
	unset npm_package_name
}

@test "./tmex -n 1234 a b c d e f g h i j k" {
	run $dir/tmex -n 1234 a b c d e f g h i j k
	assert_output -p "Invalid input: --layout=1234 is too small for number of commands provided"
}

@test "./tmex -n 1[2{34}5]6 a b c d e f g h i j k l m n o" {
	run $dir/tmex -n 1[2{34}5]6 a b c d e f g h i j k l m n o
	assert_output -p "Invalid input: --layout=1[2{34}5]6 is too small for number of commands provided"
}

# ensure nested tmex commands will select and split their current pane
# instead of spawning a nested tmux session
@test "TMUX_PANE=%5 ./tmex testsessionname a b c" {
	export TMUX_PANE="%5"
	run $dir/tmex testsessionname a b c
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

@test "TMUX_PANE=%5 ./tmex --kill" {
	export TMUX_PANE="%5"
	run $dir/tmex --kill
	assert_output -p "kill-session -t ${TMUX_PANE}"
	assert_success
	unset TMUX_PANE
}

@test "TMUX_PANE=%5 ./tmex -k" {
	export TMUX_PANE="%5"
	run $dir/tmex -k
	assert_output -p "kill-session -t ${TMUX_PANE}"
	assert_success
	unset TMUX_PANE
}

@test "./tmex testsessionname --kill" {
	run $dir/tmex testsessionname --kill
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "./tmex testsessionname -k" {
	run $dir/tmex testsessionname -k
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "./tmex --kill testsessionname" {
	run $dir/tmex --kill testsessionname
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "./tmex -k testsessionname" {
	run $dir/tmex -k testsessionname
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

function layout_with_new_pct_flags() {
	sed -E 's/ -p([0-9]+)/ -l\1%/g' <<< "$1"
}

# ensure running with a newer version of tmux (>3.0) causes
# 'split-window -l<value>%' to be used instead of 'split-window -p<value>',
# see https://github.com/tmux/tmux/blob/master/CHANGES#L663-L665 for details
@test "TMUX_VERSION=3.0 ./tmex testsessionname 1234" {
	export TMUX_VERSION=3.0
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=2.3.4 ./tmex testsessionname 1234" {
	export TMUX_VERSION=2.3.4
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=1 ./tmex testsessionname 1234" {
	export TMUX_VERSION=1
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=3.1 ./tmex testsessionname 1234" {
	export TMUX_VERSION=3.1
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=3.3a ./tmex testsessionname 1234" {
	export TMUX_VERSION=3.3a
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=3.4 ./tmex testsessionname 1234" {
	export TMUX_VERSION=3.4
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}
@test "TMUX_VERSION=123.456.789.xyz ./tmex testsessionname 1234" {
	export TMUX_VERSION=123.456.789.xyz
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	unset TMUX_VERSION
}

# ensure warning is shown ONLY if current tmux version is not available
@test "TMUX_VERSION='' ./tmex testsessionname 1234" {
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
  refute_output -p "Warning: current tmux version could not be determined"
	assert_success
	export TMUX_VERSION=''
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
  assert_output -p "Warning: current tmux version could not be determined"
  # when version is unavailable, an older tmux version should be assumed:
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	assert_success
	unset TMUX_VERSION
}

# ensure warning is suppressed if requested via env var
@test "TMUX_VERSION='' TMEX_SUPPRESS_WARNING_PCT_FLAGS=1 ./tmex testsessionname 1234" {
	export TMUX_VERSION=''
  export TMEX_SUPPRESS_WARNING_PCT_FLAGS=1
	run $dir/tmex testsessionname 1234
	assert_output -p "new-session -s testsessionname"
  refute_output -p "Warning: current tmux version could not be determined"
  # an older tmux version should still be assumed, regardless of warning suppression:
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	assert_success
	unset TMUX_VERSION
  unset TMEX_SUPPRESS_WARNING_PCT_FLAGS
}
