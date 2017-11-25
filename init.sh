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

if [ -e registry.json ]; then
    echo "Already initalized."
    exit 1
fi

cat >> registry.json << EOL
{
  "installedLibraries": {}
}
EOL

echo "Created new registry.json (list of installed libraries)."
echo "Now use './add.sh library version main main-minified' to add some libraries."
