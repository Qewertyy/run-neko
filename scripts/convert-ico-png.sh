#!/bin/bash

# This script converts .ico files to .png format using sips.

read -rp "enter the src directory containing .ico files: " SRC_DIR
read -rp "enter the output directory for .png files: " DST_DIR

if [ ! -d "$SRC_DIR" ]; then
  echo "error: src directory does not exist."
  exit 1
fi

mkdir -p "$DST_DIR"

for file in "$SRC_DIR"/*.ico; do
  # Skip if no .ico files
  [ -e "$file" ] || continue

  filename=$(basename "$file" .ico)

  IFS="_" read -ra parts <<< "$filename"
  newname="${parts[*]}"
  newname="${newname// /_}"

  output="$DST_DIR/$newname.png"

  sips -s format png "$file" --out "$output"

  echo "Converted: $file -> $output"
done
