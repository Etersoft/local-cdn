#!/bin/bash

source functions.sh


if [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ $# -le 3 ] ; then
    echo 'Usage: add.sh <package> <version> <main> <main-minified>'
    echo '  Main and main-minified are paths to files inside package'
    echo '    Example (React): ./add.sh react latest umd/react.development.js umd/react.production.min.js'
    echo '  Version should be a number or "latest"'
    echo '    Example (jQuery): ./add.sh jquery 1 dist/jquery.js dist/jquery.min.js'
    exit 0
fi

re='^[0-9\.]+$'

force=''
if [ "$1" = "-f" ] || [ "$1" = "--force" ] ; then
    force="$1"
    shift
fi

library="$1"
version="$2"
main="$3"
main_minified="$4"

# note: do not quote regexp here (SC2076)
if ! [[ "$version" =~ $re ]] && [ "$version" != "latest" ]; then
    fatal "Bad version: $version"
fi

epm assure jq || exit
epm assure npm || exit


if ! npm view "$library" > /dev/null ; then
    echo 'Failed to get package info. Are you sure it exists?'
    echo 'If not sure, check npm-debug.log for details.'
    exit 1
fi

[ -n "$force" ] && remove_package "$library" "$version"

add_package "$library" "$version" "$main" "$main_minified" || fatal

registry_add_library_version "$library" "$version" "$main" "$main_minified"
