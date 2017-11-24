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

if ! [[ $2 =~ $re ]] && [ "$2" != "latest" ]; then
    echo "Bad version: $2"
    exit 1
fi

epm assure jq || exit

package="$1"
version="$2"
main="$3"
main_minified="$4"

if ! npm view "$1" > /dev/null 2>&1; then
    echo 'Failed to get package info. Are you sure it exists?'
    echo 'If not sure, check npm-debug.log for details.'
    exit 1
fi


add_package "$package" "$version" "$main" "$main_minified"
registry_add_library_version "$package" "$version" "$main" "$main_minified"
