#!/bin/bash

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
