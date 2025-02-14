#!/bin/bash

# Get the current date in YYYY-MM-DD format
DATE=$(date +"%Y-%m-%d")
BASE_NAME="misc/pipeline_overview_$DATE"
OUTPUT_FILE="${BASE_NAME}.txt"

# Check for existing files and add a numeric suffix if needed
COUNT=1
while [[ -f "$OUTPUT_FILE" ]]; do
    OUTPUT_FILE="${BASE_NAME}_$COUNT.txt"
    ((COUNT++))
done

# Allowed file extensions
EXTENSIONS=("pde" "r" "py")

# Create or overwrite the output file
echo "Exporting pipeline files to $OUTPUT_FILE..."
echo "==== Pipeline Overview ====" > "$OUTPUT_FILE"

# Find and process allowed files
for ext in "${EXTENSIONS[@]}"; do
    while IFS= read -r file; do
        echo -e "\n\n===== $file =====\n" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
    done < <(find . -type f -iname "*.$ext")
done

echo "Done! Check $OUTPUT_FILE."
