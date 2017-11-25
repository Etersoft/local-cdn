fatal () {
    echo "Error: $*" >&2
    exit 1
}

add_package () {
    local library="$1"
    local version="$2"
    local main="$3"
    local minified="$4"

    #if [ -e "packages/$library/$version" ]; then
    #    rm -rf "packages/$library/$version"
    #    echo "Removed old version (packages/$library/$version)"
    #fi
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

    mkdir -p "$public_base"
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
EOL
    echo "    \"$1\": \"$semver_version\"" >> "packages/$1/$2/package.json"
    cat >> "packages/$1/$2/package.json" << EOL
  }
}
EOL
}

install_or_update_package () {
    cd "packages/$1/$2/"
    if ! npm i > /dev/null 2>&1; then
        fatal "Failed to install $1@$2"
    fi
    cd ../../../
}

link_and_print () {
    if ! [ -e "$1" ]; then
        fatal "File not found: $1"
    fi
    ln -f "$1" "$2"
    echo "Created hardlink: $2 -> $1"
}

registry_add_library_version () {
    new_registry=$(cat registry.json | jq --arg lib "$1" --arg version "$2" --arg main "$3" --arg minified "$4" ".installedLibraries[\"$1\"][\"$2\"] = {"main": \$main, "minified": \$minified}") || fatal "jq error"
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
