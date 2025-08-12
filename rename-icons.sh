#!/bin/bash

cd icons

for file in *.png; do
    if [[ $file =~ ^([0-9]+)\.png$ ]]; then
        size=${BASH_REMATCH[1]}
        newname="icon-${size}x${size}.png"
        
        if [ "$file" != "$newname" ]; then
            mv "$file" "$newname"
            echo "Renamed: $file -> $newname"
        else
            echo "Already named correctly: $file"
        fi
    else
        echo "Skipping: $file (not a numeric filename)"
    fi
done

echo "Icon renaming complete!"
