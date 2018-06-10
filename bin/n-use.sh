#!/usr/bin/env bash

# This script is meant to be sourced to provide per-session node.js version
# management. It introduces the command `n use <version>` to change the default
# node version for the current shell. The version can:
#   - Begin with a v
#   - Be omitted, if a .nvmrc file is present in the current directory and
#           contains the node version in its first line.
#   - Be one of `latest`, `lts`, `stable`. In this case, n itself is used to
#           resolve it to a version number.

# Need aliasing for npm global packages
shopt -s expand_aliases

# This variable is global for DRY purposes
# N executable
N_BIN=$(which n)

# This function makes the provided node version the default for this session.
#
# Arguments:
#   - $1: The node verison number to be set as default. The version number
#         doesn't undergo any further processing, not even leading v removal.
n-activate() {
    local VERSION="$1"

    # Installation paths for n and the node version
    local N_PREFIX
    N_PREFIX=$(dirname "$N_BIN" | xargs -i readlink -f '{}/..')
    local N_VERSION_PATH
    N_VERSION_PATH=$(find "$N_PREFIX/n" -path "*$VERSION")

    # Node version not installed. Would need root privileges to install it.
    if [[ -z "$N_VERSION_PATH" ]]; then
        echo 1>&2 "Node version $VERSION not installed!"
        return 1
    fi

    # Adding node version binaries path with high priority
    PATH="$N_VERSION_PATH/bin-node:$PATH"

    # Unaliasing current node aliases
    local NODE_ALIASES
    NODE_ALIASES="$(alias | grep node_modules | grep -oP '\S+\w+(?=\=)')"
    [[ -n "$NODE_ALIASES" ]] && unalias $NODE_ALIASES

    # Aliasing global installed packages.

    # If jq is available, the package.json of global packages of the activated
    # version are scanned for package binaries, that are then aliased
    if which jq &> /dev/null; then
        while read JS_NAME JS_BIN; do

            # readlink normalizes relative binaries path in package.json
            JS_BIN=$(readlink -f "$JS_BIN")
            # shellcheck disable=SC2139
            alias "$JS_NAME"="$JS_BIN"
        done < <(find "$N_VERSION_PATH/lib/node_modules" -maxdepth 1 \
                        -mindepth 1 -type d \
                -exec jq -r '
                    .bin |
                    to_entries |
                    map(.key + " {}/" + .value) |
                    .[]' "{}/package.json" \;)

    # Every binary linking to a node_modules path is aliased to the same target
    # but in the new node version, if it exists. Otherwise, the alias is to an
    # error message
    else
        for JS_BIN in "$N_PREFIX/bin/"*; do
            LINK_TARGET=$(readlink "$JS_BIN")

            # Skipping non-node_modules links
            grep 'node_modules' &> /dev/null <<<"$LINK_TARGET" || continue

            # Path to the target for the new node version: either replace
            # the parent directory or the node version.
            JS_PATH=$(sed -E "s|([[:digit:]]+\.?)+|$VERSION|g; \
                s|\.\.|$N_VERSION_PATH|g" <<<"$LINK_TARGET")
            ALIAS_NAME="$(basename "$JS_BIN")"

            if [[ -f "$JS_PATH" ]]; then
                # shellcheck disable=SC2139
                alias "$ALIAS_NAME"="$JS_PATH"
            else
                # shellcheck disable=SC2139,SC2140
                alias "$ALIAS_NAME"="echo $ALIAS_NAME is not installed for version $VERSION && false"
            fi
        done
    fi

    echo "Node version $VERSION activated"
}

# This function mainly deals with version number formatting before calling
# n-activate. The version can:
#   - Begin with a v
#   - Be omitted, if a .nvmrc file is present in the current directory and
#           contains the node version in its first line.
#   - Be one of `latest`, `lts`, `stable`. In this case, n itself is used to
#           resolve it to a version number.
#
# Arguments:
#   - $1: The node version to be used. Read above for all the supported cases.
n-use() {
    local VERSION="$1"

    # No version specified; checking for .nvmrc
    if [[ -z "$VERSION" ]]; then

        # .nvmrc not found
        if [[ ! -f .nvmrc ]]; then
            echo 1>&2 'No version specified!'
            return 1
        fi

        # Reading version from .nvmrc
        VERSION=$(head -n 1 .nvmrc)
    fi

    # Resolving named version with n
    case "$VERSION" in
        latest|lts|stable)
            VERSION=$("$N_BIN" --"$VERSION")
            ;;
    esac

    # Removing leading v and activating
    n-activate "${VERSION#v}"
}

# This function takes care of the n use command, delegating anythign else to
# n, so as to give the impression of adding a command to n itself.
#
# Arguments:
#   - $1: beside what n supports, 'use' is added.
#   - $2: Anything supported by n, with the addition of a version.
#   - $@: Anything that n supports
n() {
    local CMD="$1"
    local VERSION="$2"

    # Implementing the `use` command
    if [[ "$CMD" == 'use' ]]; then
        n-use "$VERSION"

    # Delegating anything else to n
    else
        "$N_BIN" "$@"
    fi
}
