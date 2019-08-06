#!/usr/bin/env bash
set -e
die()
{
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_input=
_arg_output=


print_help()
{
	printf '%s\n' "The general script's help msg"
	printf 'Usage: %s [-i|--input <arg>] [-o|--output <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-i, --input: input location (no default)"
	printf '\t%s\n' "-o, --output: output location (no default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-i|--input)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_input="$2"
				shift
				;;
			--input=*)
				_arg_input="${_key##--input=}"
				;;
			-i*)
				_arg_input="${_key##-i}"
				;;
			-o|--output)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_output="$2"
				shift
				;;
			--output=*)
				_arg_output="${_key##--output=}"
				;;
			-o*)
				_arg_output="${_key##-o}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"

if [ -z "$_arg_input" ]
then
  _PRINT_HELP=yes die "Missing input"
fi

if [ -z "$_arg_output" ]
then
  _PRINT_HELP=yes die "Missing output"
fi

parentdir="$(dirname "$_arg_input")"
protoc -I$parentdir -I$(pwd)/protobuf-solidity/src/protoc/include --plugin=protoc-gen-sol=$(pwd)/protobuf-solidity/src/protoc/plugin/gen_sol.py --sol_out=gen_runtime=ProtoBufRuntime.sol:$_arg_output $_arg_input
