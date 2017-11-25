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

update_all_packages () {
    local libraries=$(registry_get_libraries)

    echo "----------"
    for library in $libraries; do
        local versions="$(registry_get_library_versions "$library")"
        for version in $versions; do
            echo "Updating $library@$version:"
            update_package "$library" "$version"
            echo "----------"
        done
    done
}

update_package () {
    local library="$1"
    local version="$2"
    local main=$(registry_get_package_main "$library" "$version")
    local main_minified=$(registry_get_package_main_minified "$library" "$version")

    add_package "$library" "$version" "$main" "$main_minified"
}


# TODO: allow update all versions of a library
if [ -z "$library" ] || [ -z "$version" ]; then
    echo 'Updating all packages from registry.json...'
    update_all_packages
    exit
fi

registry_package_exists "$library" "$version" || fatal "Package is not installed: $library@$version"

update_package "$library" "$version"
