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
