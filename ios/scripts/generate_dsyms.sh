#!/bin/bash

# Script to generate dSYMs for Agora frameworks
echo "Generating dSYMs for Agora frameworks..."

# Find all Agora frameworks in the app bundle
FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ -d "$FRAMEWORKS_DIR" ]; then
    for framework in "$FRAMEWORKS_DIR"/*.framework; do
        if [[ "$framework" == *"Agora"* ]] || [[ "$framework" == *"aosl"* ]] || [[ "$framework" == *"video_"* ]]; then
            framework_name=$(basename "$framework" .framework)
            echo "Processing framework: $framework_name"
            
            # Generate dSYM if it doesn't exist
            dsym_path="${BUILT_PRODUCTS_DIR}/${framework_name}.framework.dSYM"
            if [ ! -d "$dsym_path" ]; then
                echo "Generating dSYM for $framework_name"
                dsymutil "$framework/$framework_name" -o "$dsym_path"
            fi
        fi
    done
fi

echo "dSYM generation completed!" 