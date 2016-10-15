#!/bin/bash

# specify custom directory to install in as the first argument
# eg. ./setup-pendata.sh /home/techgaun/pentest/files
# defaults to $HOME/pentest

ROOT_DIR=${1:-$HOME/pentest}
PAYLOAD_DIR="${ROOT_DIR}/payloads"

if [[ ! -e "${ROOT_DIR}" ]]; then
  echo "${ROOT_DIR} does not exist. Creating..."
  mkdir -p "${ROOT_DIR}"
fi
mkdir -p "${PAYLOAD_DIR}"

git clone https://github.com/danielmiessler/SecLists.git "${ROOT_DIR}/seclist"
git clone https://github.com/nepalihackers/xss-payloads.git "${PAYLOAD_DIR}/xss"
git clone https://github.com/xsuperbug/payloads.git "${PAYLOAD_DIR}/badfiles"
git clone https://github.com/minimaxir/big-list-of-naughty-strings.git "${PAYLOAD_DIR}/badstrings"
git clone https://github.com/fuzzdb-project/fuzzdb.git "${PAYLOAD_DIR}/fuzzdb"
git clone https://github.com/1N3/IntruderPayloads.git "${PAYLOAD_DIR}/intruder-payloads"
git clone https://github.com/techgaun/bash-backdoor.git "${PAYLOAD_DIR}/bash-backdoor"
