#!/bin/bash

source functions.sh


if [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ $# -eq 1 ] ; then
    echo 'Usage: update.sh [<package> <version>]'
    exit 0
fi

epm assure jq || exit
epm assure npm || exit

library="$1"
version="$2"

# TODO: allow update all versions of a library
if [ -z "$library" ] || [ -z "$version" ]; then
    echo 'Updating all packages from registry.json...'
    update_all_packages
    exit
fi

registry_package_exists "$library" "$version" || fatal "Package is not installed: $library@$version"

update_package "$library" "$version"
