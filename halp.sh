#!/usr/bin/env sh
program="$1"
try_info () {
  if [ "$(info -w "$program")" = "dir" ]; then
    return 1
  else
    info "$program"
  fi
}
try_help () {
  command -v "$program" >/dev/null 2>&1
  if [ $? != 0 ]; then
    printf "Command $program not found\n"
    return 1
  else
    "$program" --help || "$program" -h || return 1
  fi
}
try_search () {
  printf "Search Google for $program? [y/N]: "
  read YES_NO
  if [ $YES_NO = 'y' ] || [ $YES_NO = 'Y' ];then
    xdg-open "https://www.google.com/search?q=$1"
  else
    exit 0
  fi
}

man "$1" || try_help || try_info || try_search
