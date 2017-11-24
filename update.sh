#!/bin/bash

source functions.sh


if [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ $# -eq 1 ] ; then
    echo 'Usage: update.sh [<package> <version>]'
    exit 0
fi

epm assure jq || exit

library="$1"
version="$2"


if [ -z "$library" ] || [ -z "$version" ]; then
    echo 'Updating all packages from registry.json...'
    update_all_packages
else
    if registry_package_exists "$library" "$version"; then
        update_package "$library" "$version"
    else
        echo "Package not installed: $library@$version"
        exit 1
    fi
fi
