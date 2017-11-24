fatal () {
    echo "Error: $*" >&2
    exit 1
}

add_package () {
    local package="$1"
    local version="$2"
    local main="$3"
    local minified="$4"

    rm -rf "packages/$package/$version"
    create_package_version "$package" "$version"
    echo "Created packages/$package/$version/package.json"
    install_or_update_package "$package" "$version"
    create_dist_link "$package" "$version" "$main" "$minified"
    echo "Installed $package@$version"
}

create_dist_link () {
    local package="$1"
    local version="$2"
    local main="$3"
    local minified="$4"

    public_base="public/$package/$version"
    package_base="packages/$package/$version/node_modules/$package"

    mkdir -p "$public_base"
    #if [ -z "$3" ]; then
    #    main_file=$(npm view "$1" main)
    #else
    local main_file="$3"
    local main_file_minified="$4"
    #fi
    link_and_print "$package_base/$main_file_minified" "$public_base/$package.min.js"
    link_and_print "$public_base/$package.min.js" "$public_base/$package.js"
    link_and_print "$package_base/$main_file" "$public_base/$package.development.js"
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
    ln "$1" "$2"
    echo "Created hardlink: $2 -> $1"
}

registry_add_library_version () {
    new_registry=$(cat registry.json | jq --arg lib "$1" --arg version "$2" --arg main "$3" --arg minified "$4" ".installedLibraries[\"$1\"][\"$2\"] = {"main": \$main, "minified": \$minified}") || fatal "jq error"
    echo "$new_registry" > registry.json
}
