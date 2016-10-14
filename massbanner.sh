#!/bin/bash

if [[ "${1}x" == "x" ]]; then
  echo "Usage: ${0} <url_lists_file>"
  exit 1
fi

if [[ ! -f "$1" ]]; then
  echo "Given file ${1} does not exist!"
  exit 2
fi

while read line; do
  echo "Url: ${line}"
  curl --connect-timeout 2 --max-time 3 -Is "${line}" | grep --color "Server:"
done < $1
