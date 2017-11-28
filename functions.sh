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

fatal () {
    echo "Error: $*" >&2
    exit 1
}

remove_package() {
    local library="$1"
    local version="$2"

    [ -e "packages/$library/$version" ] || return

    rm -rf "packages/$library/$version"
    echo "Removed old version (packages/$library/$version)"
}

add_custom_link () {
    local library="$1"
    local version="$2"
    local local_name="$3"

    local public_name="$(cat registry.json | jq -r ".installedLibraries[\"$library\"][\"$version\"].customLinks[\"$local_name\"]")"

    local public_base="public/$library/$version"
    local library_base="packages/$library/$version/node_modules/$library"

    link_and_print "$library_base/$local_name" "$public_base/$public_name"
}

add_custom_links () {
    local library="$1"
    local version="$2"

    if [ "$(cat registry.json | jq -r ".installedLibraries[\"$library\"][\"$version\"].customLinks")" != "null" ]; then
        local links="$(cat registry.json | jq -r ".installedLibraries[\"$library\"][\"$version\"].customLinks | keys[]")"
        for link in $links; do
            add_custom_link "$library" "$version" "$link"
        done
    fi
}

add_package () {
    local library="$1"
    local version="$2"
    local main="$3"
    local minified="$4"

    if ! [ -e "packages/$library/$version" ]; then
        create_package_version "$library" "$version"
        echo "Created packages/$library/$version/package.json"
    fi
    install_or_update_package "$library" "$version"
    create_dist_link "$library" "$version" "$main" "$minified"
    echo "Installed $library@$version"
}

create_dist_link () {
    local library="$1"
    local version="$2"
    local main_file="$3"
    local main_file_minified="$4"

    public_base="public/$library/$version"
    library_base="packages/$library/$version/node_modules/$library"

    mkdir -p "$public_base" || fatal
    #if [ -z "$3" ]; then
    #    main_file=$(yarn info "$1" main)
    #else
    #fi
    link_and_print "$library_base/$main_file_minified" "$public_base/$library.min.js"
    link_and_print "$public_base/$library.min.js" "$public_base/$library.js"
    link_and_print "$library_base/$main_file" "$public_base/$library.development.js"
    add_custom_links "$library" "$version"
}

create_package_version () {
    if [ "$2" == "latest" ]; then
        semver_version="*"
    else
        semver_version="$2.*"
    fi

    mkdir -p "packages/$1/$2"
    rm -f "packages/$1/$2/package.json"
    # private: true is to avoid yarn warnings
    cat >> "packages/$1/$2/package.json" << EOL
{
  "name": "",
  "description": "",
  "version": "0.1.0",
  "dependencies": {
      "$1": "$semver_version"
  },
  "private": true
}
EOL
}

install_or_update_package () {
    cd "packages/$1/$2/" || fatal

    if [ -e yarn.lock ]; then
        yarn upgrade > /dev/null || fatal "Failed to update $1@$2"
    else
        yarn install > /dev/null || fatal "Failed to install $1@$2"
    fi

    cd ../../../ || fatal
}

link_and_print () {
    [ -e "$1" ] || fatal "File not found: $1"

    local target_dirname="$(dirname "$2")"
    if [ "$target_dirname" != "." ]; then
        mkdir -p "$target_dirname" || fatal
    fi

    ln -f "$1" "$2" || fatal
    echo "Created hardlink: $2 -> $1"
}

registry_add_library_version () {
    new_registry=$(cat registry.json | jq --arg lib "$1" --arg version "$2" --arg main "$3" --arg minified "$4" ".installedLibraries[\"$1\"][\"$2\"] = {\"main\": \$main, \"minified\": \$minified}") || fatal "jq error"
    echo "$new_registry" > registry.json
}

registry_get_libraries () {
    cat registry.json | jq -r ".installedLibraries | keys[]"
}

registry_get_library_versions () {
    cat registry.json | jq -r ".installedLibraries[\"$1\"] | keys[]"
}

registry_get_package_main () {
    cat registry.json | jq -r ".installedLibraries[\"$1\"][\"$2\"].main"
}

registry_get_package_main_minified () {
    cat registry.json | jq -r ".installedLibraries[\"$1\"][\"$2\"].minified"
}

registry_package_exists () {
    local result=$(cat registry.json | jq ".installedLibraries[\"$1\"][\"$2\"]")
    [ "$result" != "null" ]
}

