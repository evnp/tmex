#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

ORIGINAL_PATH="$PATH"

function setup_file() {
	# ensure TMUX_PANE is not set at beginning of test so that tests can be run
	# from within tmux (TMUX_PANE handling is tested explicitly at end of suite)
	unset TMUX_PANE
	export TMUX_VERSION="3.0"
	mock_tmux
}

function teardown_file() {
	unset TMUX_PANE
	unset TMUX_VERSION
	restore_tmux
}

function mock_tmux() {
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

function restore_tmux() {
	rm -rf testbin
	export PATH="$ORIGINAL_PATH"
}

function run_tmex() {
	local cmd
	cmd="${BATS_TEST_DESCRIPTION}"
	cmd="${cmd/${BATS_TEST_NUMBER} /}"
	cmd="${cmd/README /}"
	cmd="${cmd/tmex/${BATS_TEST_DIRNAME}/tmex}"
	if [[ "${cmd}" =~ ^([A-Z_]+=[^ ]*) ]]; then
		# handle env var declarations placed before test command
		export "${BASH_REMATCH[1]}"
		run ${cmd/${BASH_REMATCH[1]} /}
	else
		run ${cmd}
	fi
}

@test "${BATS_TEST_NUMBER} tmex" {
	run_tmex
	assert_output -p "Invalid input: Session name required."
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --help" {
	run_tmex
	assert_output -p "Usage:"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex -h" {
	run_tmex
	assert_output -p "Usage:"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --version" {
	run_tmex
	assert_output -p "tmex"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex -v" {
	run_tmex
	assert_output -p "tmex"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --npm" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex -n" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --npm" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -n" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_success
}

function print_layout() {
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

	echo "${expected}"
}

function assert_layout() {
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

@test "${BATS_TEST_NUMBER} tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1..2..3..4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1..2..3..4"
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l .1..2..3..4." {
	run_tmex
	assert_output -p "Invalid input: --layout=.1..2..3..4."
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1..2..3..4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1..2..3..4"
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=.1..2..3..4." {
	run_tmex
	assert_output -p "Invalid input: --layout=.1..2..3..4."
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1..2..3..4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1..2..3..4"
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout .1..2..3..4." {
	run_tmex
	assert_output -p "Invalid input: --layout=.1..2..3..4."
	assert_output -p "cannot contain multiple . characters in a row"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -f5 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 123+++4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -f5 123+++4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 123+++4 -f5" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -f6 123+++4" {
  # --focus arg value should take precedence over layout focus characters
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t6"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 123+++4 -f6" {
  # --focus arg value should take precedence over layout focus characters
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t6"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 123-4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l1234 -f-5" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t-5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -f 15 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t15"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1234 -f-15" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t-15"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1234 --focus=0" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1+234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1-234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1+234 --focus=0" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1-234 --focus=0" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1+234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1-234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1+++234" {
  # --focus arg value should take precedence over layout focus characters
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1---234" {
  # --focus arg value should take precedence over layout focus characters
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1-+-234" {
	run_tmex
	assert_output -p "Invalid input: --layout=1-+-234"
	assert_output -p "cannot contain both + and - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1+-234" {
	run_tmex
	assert_output -p "Invalid input: --layout=1+-234"
	assert_output -p "cannot contain both + and - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1---23-4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1---23-4"
	assert_output -p "cannot contain multiple groups of - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1+++23+4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1+++23+4"
	assert_output -p "cannot contain multiple groups of + characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1---23+4" {
	run_tmex
	assert_output -p "Invalid input: --layout=1---23+4"
	assert_output -p "cannot contain multiple groups of + and - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1---234-" {
	run_tmex
	assert_output -p "Invalid input: --layout=1---234-"
	assert_output -p "cannot contain multiple groups of - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1+++234+" {
	run_tmex
	assert_output -p "Invalid input: --layout=1+++234+"
	assert_output -p "cannot contain multiple groups of + characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1---234+" {
	run_tmex
	assert_output -p "Invalid input: --layout=1---234+"
	assert_output -p "cannot contain multiple groups of + and - characters"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l ---1234-" {
	run_tmex
	assert_output -p "Invalid input: --layout=---1234-"
	assert_output -p "cannot start with - character"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l +++1234+" {
	run_tmex
  assert_output -p "Invalid input: --layout=+++1234+"
	assert_output -p "cannot start with + character"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l ---1234+" {
	run_tmex
	assert_output -p "Invalid input: --layout=---1234+"
	assert_output -p "cannot start with - character"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1234 -f=abcdefg" {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -fl1234" {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname 1234 -f5" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -f-5 -l1234 " {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t-5"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --focus=0 -l 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t0"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1234 -f 15" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234} select-pane -t15"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -f=abcdefg --layout 1234 " {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {1111}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {1111}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {1.1.1.1}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {1.1.1.1}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {1.1.1.1.}.1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.1.1.1.1}1.2.3.4." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9999}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9999}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.9.9.9}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.9.9.9}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.9.9.9.}.1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.9.9.9.9}1.2.3.4." {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {4321}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {4321}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {4.3.2.1}1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {4.3.2.1}1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {4.3.2.1.}.1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.4.3.2.1}1.2.3.4." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_4321}"
	assert_success
}

shorthand_layout_123456789="
	H -p80 H -p28 L H -p42 L H -p47 R H -p45 R H -p30 L H -p43 R H -p33
	L L L L L L L L R V -p50 R V -p67 V -p50 R V -p50 U V -p50 D V -p50
	R V -p80 V -p50 U V -p50 D V -p50 R V -p50 U V -p67 V -p50 D V -p67
	V -p50 R V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 R V -p50 U V -p50
	U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 R V -p89 V -p50 U V -p50
	U V -p50 D V -p50 D V -p50 U V -p50 D V -p50
"

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {987654321}123456789" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_123456789}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {987654321}1.2.3.4.5.6.7.8.9" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_123456789}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.8.7.6.5.4.3.2.1}123456789" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_123456789}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.8.7.6.5.4.3.2.1}1.2.3.4.5.6.7.8.9" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_123456789}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.9.8.7.6.5.4.3.2.1.}.1.2.3.4.5.6.7.8.9." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_123456789}"
	assert_success
}

shorthand_layout_12_34_56="
	H -p33 H -p0 L L V -p50 U V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p50 U V -p67 V -p50 D V -p67 V -p50 R V -p50 U V -p94 V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p94 V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 R V -p50 U V -p50 U V -p50 U V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p50 U V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p50 U V -p50 U V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p50 U V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50 D V -p86 V -p50 U V -p67 V -p50 D V -p67 V -p50
"

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {654.321}12.34.56" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_12_34_56}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.654.321.}.12.34.56." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_12_34_56}"
	assert_success
}

shorthand_layout_1_23_45_67_8_9="
	H -p22 L H -p94 H -p43 R H -p7 H -p33 L L L L L R V -p96 V -p50 U V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 D V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 R V -p98 V -p50 U V -p50 U V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 D V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 D V -p50 U V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 D V -p91 V -p50 U V -p80 V -p50 U V -p50 D V -p50 D V -p80 V -p50 U V -p50 D V -p50 R V -p99 V -p50 U V -p97 V -p50 U V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p97 V -p50 U V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 D V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 R V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50 R V -p89 V -p50 U V -p50 U V -p50 D V -p50 D V -p50 U V -p50 D V -p50
"

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {9.87.65.43.2.1}1.23.45.67.8.9" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_1_23_45_67_8_9}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {.9.87.65.43.2.1.}.1.23.45.67.8.9." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout_shorthand "${shorthand_layout_1_23_45_67_8_9}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3{}34" {
	run_tmex
	assert_output -p "Invalid input: --layout=3{}34"
	assert_output -p "cannot contain empty { } brackets"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3{+}34" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3{+}3.4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout .3{+}.3.4." {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3[5{}]4" {
	run_tmex
	assert_output -p "Invalid input: --layout=3[5{}]4"
	assert_output -p "cannot contain empty { } brackets"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3[5{+}]4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3.[5{+}.]4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3.[5{+}].4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 3[.5{+}.]4" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout .3[5{+}].4." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_grid5}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout {+}3[5]4" {
	run_tmex
	assert_output -p "Invalid input: --layout={+}3[5]4"
	assert_output -p "cannot start with {+} clause"
	refute_output -p "new-session -s testsessionname"
	assert_failure
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

@test "${BATS_TEST_NUMBER} tmex testsessionname -t 1234" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -t 1.2.3.4" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -t .1.2.3.4." {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname 1234 -t" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1.2.3.4 -t " {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname .1.2.3.4. -t" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l1234 -t" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l1.2.3.4 -t" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l.1.2.3.4. -t" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl1234" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl1.2.3.4" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl.1.2.3.4." {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl 1234" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl 1.2.3.4" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl .1.2.3.4." {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=1234" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=1.2.3.4" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=.1.2.3.4." {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1234 --transpose" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1.2.3.4 --transpose" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=.1.2.3.4. --transpose" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=1234" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=1.2.3.4" {
	run_tmex
	assert_layout "${layout_1234_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=.1.2.3.4." {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname 1[2{34}5]6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1.[2{3.4}.5].6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname .1[.2{34}5]6." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l1[2{34}5]6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l1.[2{3.4}.5].6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l.1[.2{34}5]6." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1[2{34}5]6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l 1.[2{3.4}.5].6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l .1[.2{34}5]6." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1[2{34}5]6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1.[2{3.4}.5].6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=.1[.2{34}5]6." {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1[2{34}5]6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout 1.[2{3.4}.5].6" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_123456}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout .1[.2{34}5]6." {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname -t 1[2{34}5]6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -t 1.[2{3.4}.5].6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -t .1[.2{34}5]6." {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname 1[2{34}5]6 -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname 1.[2{3.4}.5].6 -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname .1[.2{34}5]6. -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -l1[2{34}5]6 -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l1.[2{3.4}.5].6 -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l.1[.2{34}5]6. -t" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl1[2{34}5]6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl1.[2{3.4}.5].6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl.1[.2{34}5]6." {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl 1[2{34}5]6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl 1.[2{3.4}.5].6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl .1[.2{34}5]6." {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=1[2{34}5]6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=1.[2{3.4}.5].6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -tl=.1[.2{34}5]6." {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1[2{34}5]6 --transpose" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=1.[2{3.4}.5].6 --transpose" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --layout=.1[.2{34}5]6. --transpose" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=1[2{34}5]6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=1.[2{3.4}.5].6" {
	run_tmex
	assert_layout "${layout_123456_transposed}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname --transpose --layout=.1[.2{34}5]6." {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname -l=44 a b c d e f g h" {
	run_tmex
	assert_layout "${layout_44}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l=4.4 a b c d e f g h" {
	run_tmex
	assert_layout "${layout_44}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l=.4.4. a b c d e f g h" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname -l=444 a b c d e f g h i j k l" {
	run_tmex
	assert_layout "${layout_444}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l=4.4.4 a b c d e f g h i j k l" {
	run_tmex
	assert_layout "${layout_444}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex testsessionname -l=.4.4.4. a b c d e f g h i j k l" {
	run_tmex
	assert_layout "${layout_444}"
	assert_success
}

# Test Shell-less mode:

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a" {
	run_tmex
	assert_layout ""
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b" {
	run_tmex
	assert_layout "
		split-window -h -p50 b
		 select-pane -L
		 select-pane -R
	"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c" {
	run_tmex
	assert_layout "
		split-window -h -p50 b
		 select-pane -L
		 select-pane -R
		split-window -v -p50 c
	"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d" {
	run_tmex
	assert_layout "
		split-window -h -p50 c
		 select-pane -L
		split-window -v -p50 b
		 select-pane -R
		split-window -v -p50 d
	"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d e" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d e f" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d e f g" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d e f g h" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex testsessionname --shellless a b c d e f g h i" {
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex --npm a" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_layout "
			 send-keys \"npm run a\" Enter
	"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --npm a b" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_layout "
			 send-keys \"npm run a\" Enter
		split-window -h -p50
			 send-keys \"npm run b\" Enter
		 select-pane -L
		 select-pane -R
	"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d e" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d e f" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d e f g" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d e f g h" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex --npm a b c d e f g h i" {
	export npm_package_name="testpackagename"
	run_tmex
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

@test "${BATS_TEST_NUMBER} tmex -n 1234 a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run_tmex
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
}
@test "${BATS_TEST_NUMBER} tmex 1234 -n a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} tmex -n 1[2{34}5]6 a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_layout "${layout_a_j}"
	assert_success
}
@test "${BATS_TEST_NUMBER} tmex 1[2{34}5]6 -n a b c d e f g h i j" {
	export npm_package_name="testpackagename"
	run_tmex
	assert_output -p "new-session -s testpackagename"
	assert_layout "${layout_a_j}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex -n 1234 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1234"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -n 1.2.3.4 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.2.3.4"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -n .1.2.3.4. a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1.2.3.4."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex 1234 -n a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1234"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex 1.2.3.4 -n a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.2.3.4"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex .1.2.3.4. -n a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1.2.3.4."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -n 1[2{34}5]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1[2{34}5]6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -n 1.[2{3.4}.5].6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.[2{3.4}.5].6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -n .1[.2{.3.4}5.]6. a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1[.2{.3.4}5.]6."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex  1[2{34}5]6 -n a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1[2{34}5]6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex 1.[2{3.4}.5].6 -n a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.[2{3.4}.5].6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex .1[.2{.3.4}5.]6. -n a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1[.2{.3.4}5.]6."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl1234 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1234"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl1.2.3.4 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.2.3.4"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl.1.2.3.4. a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1.2.3.4."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl1[2{34}5]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1[2{34}5]6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl1.[2{3.4}.5].6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.[2{3.4}.5].6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl.1[.2{.3.4}5.]6. a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1[.2{.3.4}5.]6."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl 1234 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1234"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl 1.2.3.4 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.2.3.4"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl .1.2.3.4. a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1.2.3.4."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl 1[2{34}5]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1[2{34}5]6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl 1.[2{3.4}.5].6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.[2{3.4}.5].6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl .1[.2{.3.4}5.]6. a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1[.2{.3.4}5.]6."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl=1234 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1234"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl=1.2.3.4 a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.2.3.4"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl=.1.2.3.4. a b c d e f g h i j k" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1.2.3.4."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	refute_layout "${layout_1234}"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nl=1[2{34}5]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1[2{34}5]6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl=1.[2{3.4}.5].6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=1.[2{3.4}.5].6"
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nl=.1[.2{.3.4}5.]6. a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --layout=.1[.2{.3.4}5.]6."
	assert_output -p "is too small for number of commands provided"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

@test "${BATS_TEST_NUMBER} tmex -nf=abc -l=.1[.2{.3.4}5.]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nf= -l=.1[.2{.3.4}5.]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}
@test "${BATS_TEST_NUMBER} tmex -nf -l=.1[.2{.3.4}5.]6 a b c d e f g h i j k l m n o" {
	run_tmex
	assert_output -p "Invalid input: --focus (-f) arg value must be an integer"
	refute_output -p "new-session -s testsessionname"
	assert_failure
}

# ensure nested tmex commands will select and split their current pane
# instead of spawning a nested tmux session
@test "${BATS_TEST_NUMBER} TMUX_PANE=%5 tmex testsessionname a b c" {
	run_tmex
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
}

@test "${BATS_TEST_NUMBER} TMUX_PANE=%5 tmex --kill" {
	run_tmex
	assert_output -p "kill-session -t ${TMUX_PANE}"
	assert_success
}

@test "${BATS_TEST_NUMBER} TMUX_PANE=%5 tmex -k" {
	run_tmex
	assert_output -p "kill-session -t ${TMUX_PANE}"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname --kill" {
	run_tmex
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex testsessionname -k" {
	run_tmex
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex --kill testsessionname" {
	run_tmex
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

@test "${BATS_TEST_NUMBER} tmex -k testsessionname" {
	run_tmex
	assert_output -p "kill-session -t testsessionname"
	assert_success
}

function layout_with_new_pct_flags() {
	sed -E 's/ -p([0-9]+)/ -l\1%/g' <<< "$1"
}

# ensure running with a newer version of tmux (>3.0) causes
# 'split-window -l<value>%' to be used instead of 'split-window -p<value>'.
# see https://github.com/tmux/tmux/blob/master/CHANGES#L663-L665 for details
@test "${BATS_TEST_NUMBER} TMUX_VERSION=3.0 tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=2.3.4 tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=1 tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=3.1 tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=3.3a tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=3.4 tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}
@test "${BATS_TEST_NUMBER} TMUX_VERSION=123.456.789.xyz tmex testsessionname 1234" {
	run_tmex
	assert_output -p "new-session -s testsessionname"
	assert_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	refute_layout "${layout_1234}"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	assert_success
}

# ensure warning is shown ONLY if current tmux version is not available
@test "${BATS_TEST_NUMBER} tmex notmuxversionset 1234" {
	unset TMUX_VERSION
	run_tmex
	assert_output -p "new-session -s notmuxversionset"
	assert_output -p "!!! WARNING: current tmux version could not be determined"
	# when version is unavailable an older tmux version should be assumed:
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	assert_success
}

# ensure warning is suppressed if requested via env var
@test "${BATS_TEST_NUMBER} TMEX_SUPPRESS_WARNING_PCT_FLAGS=1 tmex notmuxversionset 1234" {
	unset TMUX_VERSION
	run_tmex
	assert_output -p "new-session -s notmuxversionset"
	refute_output -p "!!! WARNING: current tmux version could not be determined"
	# an older tmux version should still be assumed regardless of warning suppression:
	assert_layout "${layout_1234}"
	refute_layout "$( layout_with_new_pct_flags "${layout_1234}" )"
	assert_success
}

# Test all tmex commands written in README.md
# Run this command:
#     grep "^tmex your-session-name" < README.md | sed -E "s/ +#.*//"
# Then diff the output against this list of commands. Add tests if any are missing.
# NOTE: All instances of "cmd a" "cmd b" etc. must be replaced with cmdA, cmdB, etc.
#       (quotes removed)
# tmex your-session-name "cmd a" "cmd b" "cmd c" ... etc.
# tmex your-session-name --npm --layout=1224 --transpose "cmd a" "cmd b" "cmd c" ... etc.
# tmex your-session-name -nt 1224 "cmd a" "cmd b" "cmd c" ... etc.
# tmex your-session-name 1224
# tmex your-session-name -l 1224
# tmex your-session-name --layout=1224
# tmex your-session-name --transpose --layout=1224
# tmex your-session-name --layout=1[2{13}1]4{4112}
# tmex your-session-name --layout={152}1[2{13}1]4{4112}
# tmex your-session-name --layout={321}234
# tmex your-session-name --transpose --layout=[234]{321}
# tmex your-session-name --layout=[[234]{321}]
# tmex your-session-name --layout=35{+}4
# tmex your-session-name --layout=31224
# tmex your-session-name --layout=8.10.12
# tmex your-session-name --layout=1234
# tmex your-session-name --layout=1.2.3.4
# tmex your-session-name --layout=11.[23]45[6.7]8.
# tmex your-session-name --layout=135+7
# tmex your-session-name --layout=135++7
# tmex your-session-name --layout=135-7
# tmex your-session-name --layout=135---7
# tmex your-session-name --layout=1357 --focus=4
# tmex your-session-name --layout=1357 -f=5
# tmex your-session-name -f=-8 1357
# tmex your-session-name -f=-10 1357
# tmex your-session-name --window abc 123 -w efg 44
# tmex your-session-name -w abc -f4 123 "echo 'cmd1'" "echo 'cmd2'" -w efg -f-2 44 "echo 'cmd 3'"
# tmex your-session-name -l 123 -f4 -w abc "echo 'cmd1'" "echo 'cmd2'" -w efg -f-2 44 "echo 'cmd 3'"
# tmex your-session-name -w- 123 -w- 44
# tmex your-session-name --window - 123 --window - 44
# tmex your-session-name -w '' 123 -w '' 44
# tmex your-session-name --window '' 123 --window '' 44
# tmex your-session-name -k
# tmex your-session-name --kill

@test "${BATS_TEST_NUMBER} README tmex your-session-name cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys cmdA Enter ; split-window -h -p50 ; send-keys cmdB Enter ; select-pane -L ; select-pane -R ; split-window -v -p50 ; send-keys cmdC Enter"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --npm --layout=1224 --transpose cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 1224 --transpose --npm cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -nt 1224 cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 1224 -nt cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -l 1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --transpose --layout=1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1224 --transpose" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -D ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1[2{13}1]4{4112}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -h -p75 ; select-pane -D ; select-pane -R ; split-window -v -p37 ; select-pane -U ; split-window -v -p20 ; select-pane -D ; split-window -v -p67"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout={152}1[2{13}1]4{4112}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p87 ; split-window -h -p29 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -h -p75 ; select-pane -D ; select-pane -R ; split-window -v -p37 ; select-pane -U ; split-window -v -p20 ; select-pane -D ; split-window -v -p67"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout={321}234" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; split-window -h -p33 ; select-pane -L ; select-pane -L ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --transpose --layout=[234]{321}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; split-window -h -p33 ; select-pane -L ; select-pane -L ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=[234]{321} --transpose" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; split-window -h -p33 ; select-pane -L ; select-pane -L ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=[[234]{321}]" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; split-window -h -p33 ; select-pane -L ; select-pane -L ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=35{+}4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p80 ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=31224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p80 ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=8.10.12" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -D ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1234" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=11.[23]45[6.7]8." {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p67 ; split-window -h -p50 ; select-pane -R ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -p91 ; split-window -v -p50 ; select-pane -U ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -D ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -h -p50 ; select-pane -D ; split-window -h -p67 ; split-window -h -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -h -p50 ; select-pane -L ; split-window -h -p67 ; split-window -h -p50 ; select-pane -R ; split-window -h -p67 ; split-window -h -p50 ; select-pane -D ; split-window -h -p86 ; split-window -h -p50 ; select-pane -L ; split-window -h -p67 ; split-window -h -p50 ; select-pane -R ; split-window -h -p67 ; split-window -h -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=135+7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=135++7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=135-7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=135---7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t6"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1357 --focus=4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --focus=4 --layout=1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --layout=1357 -f=5" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -f=5 --layout=1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -f=-8 1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t-8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 1357 -f=-8" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t-8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -f=-10 1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t-10"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 1357 -f=-10" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p50 ; select-pane -L ; split-window -h -p50 ; select-pane -R ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -R ; split-window -v -p80 ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p86 ; split-window -v -p50 ; select-pane -U ; split-window -v -p67 ; split-window -v -p50 ; select-pane -D ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t-10"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --window abc 123 -w efg 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; new-window -n efg ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 123 --window abc -w efg 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; new-window -n efg ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -w abc -f4 123 cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -p67 ; send-keys cmdB Enter ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name 123 -w abc -f4 cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -p67 ; send-keys cmdB Enter ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -l 123 -f4 -w abc cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -p67 ; send-keys cmdB Enter ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -f4 -l 123 -w abc cmdA cmdB -w efg 44 -f-2 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -p67 ; send-keys cmdB Enter ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -w- 123 -w- 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; new-window ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --window - 123 --window - 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -p67 ; split-window -h -p50 ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -p50 ; select-pane -R ; split-window -v -p67 ; split-window -v -p50 ; new-window ; split-window -h -p50 ; select-pane -L ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50 ; select-pane -R ; split-window -v -p50 ; select-pane -U ; split-window -v -p50 ; select-pane -D ; split-window -v -p50"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name -k" {
	run_tmex
	assert_output -p "kill-session -t your-session-name"
	assert_success
}
@test "${BATS_TEST_NUMBER} README tmex your-session-name --kill" {
	run_tmex
	assert_output -p "kill-session -t your-session-name"
	assert_success
}

@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys cmdA Enter ; split-window -h -l50% ; send-keys cmdB Enter ; select-pane -L ; select-pane -R ; split-window -v -l50% ; send-keys cmdC Enter"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --npm --layout=1224 --transpose cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 1224 --transpose --npm cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -nt 1224 cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 1224 -nt cmdA cmdB cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; send-keys \"npm run cmdA\" Enter ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; send-keys \"npm run cmdB\" Enter ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; send-keys \"npm run cmdC\" Enter ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -l 1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --transpose --layout=1224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1224 --transpose" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -U ; select-pane -U ; select-pane -U ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -D ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1[2{13}1]4{4112}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -h -l75% ; select-pane -D ; select-pane -R ; split-window -v -l37% ; select-pane -U ; split-window -v -l20% ; select-pane -D ; split-window -v -l67%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout={152}1[2{13}1]4{4112}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l87% ; split-window -h -l29% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -h -l75% ; select-pane -D ; select-pane -R ; split-window -v -l37% ; select-pane -U ; split-window -v -l20% ; select-pane -D ; split-window -v -l67%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout={321}234" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; split-window -h -l33% ; select-pane -L ; select-pane -L ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --transpose --layout=[234]{321}" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; split-window -h -l33% ; select-pane -L ; select-pane -L ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=[234]{321} --transpose" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; split-window -h -l33% ; select-pane -L ; select-pane -L ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=[[234]{321}]" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; split-window -h -l33% ; select-pane -L ; select-pane -L ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=35{+}4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l80% ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=31224" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l80% ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=8.10.12" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -D ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1234" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1.2.3.4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=11.[23]45[6.7]8." {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l67% ; split-window -h -l50% ; select-pane -R ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -L ; split-window -v -l91% ; split-window -v -l50% ; select-pane -U ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -D ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -h -l50% ; select-pane -D ; split-window -h -l67% ; split-window -h -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -h -l50% ; select-pane -L ; split-window -h -l67% ; split-window -h -l50% ; select-pane -R ; split-window -h -l67% ; split-window -h -l50% ; select-pane -D ; split-window -h -l86% ; split-window -h -l50% ; select-pane -L ; split-window -h -l67% ; split-window -h -l50% ; select-pane -R ; split-window -h -l67% ; split-window -h -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=135+7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=135++7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=135-7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=135---7" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t6"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1357 --focus=4" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --focus=4 --layout=1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --layout=1357 -f=5" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -f=5 --layout=1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t5"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -f=-8 1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t-8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 1357 -f=-8" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t-8"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -f=-10 1357" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t-10"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 1357 -f=-10" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l50% ; select-pane -L ; split-window -h -l50% ; select-pane -R ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -R ; split-window -v -l80% ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l86% ; split-window -v -l50% ; select-pane -U ; split-window -v -l67% ; split-window -v -l50% ; select-pane -D ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t-10"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --window abc 123 -w efg 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; new-window -n efg ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 123 --window abc -w efg 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; new-window -n efg ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -w abc -f4 123 cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -l67% ; send-keys cmdB Enter ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name 123 -w abc -f4 cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -l67% ; send-keys cmdB Enter ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -l 123 -f4 -w abc cmdA cmdB -w efg -f-2 44 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -l67% ; send-keys cmdB Enter ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -f4 -l 123 -w abc cmdA cmdB -w efg 44 -f-2 cmdC" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; rename-window abc ; send-keys cmdA Enter ; split-window -h -l67% ; send-keys cmdB Enter ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; select-pane -t4 ; new-window -n efg ; send-keys cmdC Enter ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -t-2"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -w- 123 -w- 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; new-window ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --window - 123 --window - 44" {
	run_tmex
	assert_output -p "new-session -s your-session-name ; split-window -h -l67% ; split-window -h -l50% ; select-pane -L ; select-pane -L ; select-pane -R ; split-window -v -l50% ; select-pane -R ; split-window -v -l67% ; split-window -v -l50% ; new-window ; split-window -h -l50% ; select-pane -L ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50% ; select-pane -R ; split-window -v -l50% ; select-pane -U ; split-window -v -l50% ; select-pane -D ; split-window -v -l50%"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name -k" {
	run_tmex
	assert_output -p "kill-session -t your-session-name"
	assert_success
}
@test "${BATS_TEST_NUMBER} README TMUX_VERSION=3.3a tmex your-session-name --kill" {
	run_tmex
	assert_output -p "kill-session -t your-session-name"
	assert_success
}
