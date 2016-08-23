#!/bin/bash

function restore {
    # restore IFS, screen and cursor
    unset IFS
    echo -e "\e[?25h\e[?1049l"
    die
}

function die() {
    # error message if exist
    [[ $1 ]] && echo -e "\033[01;31mERROR!\033[01;00m ${1}"
    exit ${2:-0}
}
trap restore TERM INT

function printHelp {
    cat - <<- END_OF_HELP
		OPTIONS:
		  -h, --help              display this help and exit
		  -n, --interval <secs>   seconds to wait between updates
		  -d, --differences       highlight changes between updates

		EXAMPLE:
		  $0 [--differences/-d] [--interval/-n <secs>] [--] <command>

	END_OF_HELP
}

# default options
SHOWDIFF=false
TIMEOUT=1

# fix for long options anyeater
set -- $(sed -E 's/(--[^=]+)=/\1 /g' <<< "$@")
# parse options
while [ $# -gt 0 ]; do
    case "$1" in
        --*|-*)
            if [[ ${#args[@]} -gt 0 ]]; then
              args=(${args[@]} "$@")
              break
            fi
            ;;&
        --help|-h)
            printHelp
            die
            ;;
        --interval|-n)
            [[ "$2" =~ ^([0-9]+\.)?[0-9]+$ ]] || die "Sleep should be number" 65
            TIMEOUT=$2
            shift
            ;;
        --differences|-d)
            SHOWDIFF=true
            ;;
        --)
            shift
            args=(${args[@]} "$@")
            break
            ;;
        --*|-*)
            printHelp
            die "Unknown option: $1" 65
            ;;
        *)
            args[${#args[@]}]="$1"
            ;;
    esac
    shift
done

# check variables
[[ ${#args} -ge 1 ]] || { printHelp; die "You should specify command." 1; }

echo -e "\e[?1049h\e[?25l"
IFS=$'\n'
while :; do
  echo -e "\e[H\e[J"

  cur=()
  i=0
  while read line; do
    cur[$((i++))]="$line"
  done <<< "$(eval ${args[@]})"

  if $SHOWDIFF; then
    for ((j=0; j<${#cur[@]}; j++)); do
      line="${cur[$j]}"
      prev_line="${prev[$j]}"
      for ((i=0; i<${#line}; i++)); do
        if [[ "${line:$i:1}" == "${prev_line:$i:1}" ]]; then
          echo -n "${line:$i:1}"
        else
          echo -ne "\e[7m${line:$i:1}\e[27m"
        fi
      done
      echo

      prev[$j]="${cur[$j]}"
    done

  else
    echo "${cur[*]}"
  fi

  sleep $TIMEOUT
done
