#!/bin/bash
#
# Copyright (C) 2017  Etersoft
# Copyright (C) 2017  Dmitry Nikulin <theowl@etersoft.ru>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

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
