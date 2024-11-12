#!/usr/bin/env bash

set -eExuo pipefail

if ! command -v "pkill" >/dev/null 2>&1; then
    printf "error: pkill not installed\n"
    exit 1
fi

python3 -V

ASCIINEMA_CONFIG_HOME="$(
    mktemp -d 2>/dev/null || mktemp -d -t asciinema-config-home
)"

export ASCIINEMA_CONFIG_HOME

TMP_DATA_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t asciinema-data-dir)"

trap 'rm -rf ${ASCIINEMA_CONFIG_HOME} ${TMP_DATA_DIR}' EXIT

asciinema() {
    python3 -m asciinema "${@}"
}

## disable notifications

printf "[notifications]\nenabled = no\n" >> "${ASCIINEMA_CONFIG_HOME}/config"

## test help message

asciinema -h

## test version command

asciinema --version

## test auth command

asciinema auth

## test play command

# asciicast v1
asciinema play -s 5 tests/demo.json
asciinema play -s 5 -i 0.2 tests/demo.json
# shellcheck disable=SC2002
cat tests/demo.json | asciinema play -s 5 -

# asciicast v2
asciinema play -s 5 tests/demo.cast
asciinema play -s 5 -i 0.2 tests/demo.cast
# shellcheck disable=SC2002
cat tests/demo.cast | asciinema play -s 5 -

## test cat command

# asciicast v1
asciinema cat tests/demo.json
# shellcheck disable=SC2002
cat tests/demo.json | asciinema cat -

# asciicast v2
asciinema cat tests/demo.cast
# shellcheck disable=SC2002
cat tests/demo.cast | asciinema cat -

## test rec command

# normal program
asciinema rec -c 'bash -c "echo t3st; sleep 2; echo ok"' "${TMP_DATA_DIR}/1a.cast"
grep '"o",' "${TMP_DATA_DIR}/1a.cast"

# very quickly exiting program
asciinema rec -c whoami "${TMP_DATA_DIR}/1b.cast"
grep '"o",' "${TMP_DATA_DIR}/1b.cast"

# signal handling
bash -c "sleep 1; pkill -28 -n -f 'm asciinema'" &
asciinema rec -c 'bash -c "echo t3st; sleep 2; echo ok"' "${TMP_DATA_DIR}/2.cast"

bash -c "sleep 1; pkill -n -f 'bash -c echo t3st'" &
asciinema rec -c 'bash -c "echo t3st; sleep 2; echo ok"' "${TMP_DATA_DIR}/3.cast"

bash -c "sleep 1; pkill -9 -n -f 'bash -c echo t3st'" &
asciinema rec -c 'bash -c "echo t3st; sleep 2; echo ok"' "${TMP_DATA_DIR}/4.cast"

# with stdin recording
echo "ls" | asciinema rec --stdin -c 'bash -c "sleep 1"' "${TMP_DATA_DIR}/5.cast"
cat "${TMP_DATA_DIR}/5.cast"
grep '"i", "ls\\n"' "${TMP_DATA_DIR}/5.cast"
grep '"o",' "${TMP_DATA_DIR}/5.cast"

# raw output recording
asciinema rec --raw -c 'bash -c "echo t3st; sleep 1; echo ok"' "${TMP_DATA_DIR}/6.raw"

# appending to existing recording
asciinema rec -c 'echo allright!; sleep 0.1' "${TMP_DATA_DIR}/7.cast"
asciinema rec --append -c uptime "${TMP_DATA_DIR}/7.cast"

# adding a marker
printf "[record]\nadd_marker_key = C-b\n" >> "${ASCIINEMA_CONFIG_HOME}/config"
(bash -c "sleep 1; printf '.'; sleep 0.5; printf '\x08'; sleep 0.5; printf '\x02'; sleep 0.5; printf '\x04'") | asciinema rec -c /bin/bash "${TMP_DATA_DIR}/8.cast"
grep '"m",' "${TMP_DATA_DIR}/8.cast"
