#!/bin/bash

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
    #    main_file=$(npm view "$1" main)
    #else
    #fi
    link_and_print "$library_base/$main_file_minified" "$public_base/$library.min.js"
    link_and_print "$public_base/$library.min.js" "$public_base/$library.js"
    link_and_print "$library_base/$main_file" "$public_base/$library.development.js"
}

create_package_version () {
    if [ "$2" == "latest" ]; then
        semver_version="*"
    else
        semver_version="$2.*"
    fi

    mkdir -p "packages/$1/$2"
    rm -f "packages/$1/$2/package.json"
    cat >> "packages/$1/$2/package.json" << EOL
{
  "name": "",
  "description": "",
  "version": "0.1.0",
  "dependencies": {
      "$1": "$semver_version"
  }
}
EOL
}

install_or_update_package () {
    cd "packages/$1/$2/" || fatal

    npm i > /dev/null || fatal "Failed to install $1@$2"

    cd ../../../ || fatal
}

link_and_print () {
    [ -e "$1" ] || fatal "File not found: $1"

    ln -f "$1" "$2"
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

