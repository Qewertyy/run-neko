#!/bin/bash

read -rp "enter the src directory containing PNGs: " SRC_DIR
read -rp "enter the destination .xcassets directory: " DST_DIR

if [ ! -d "$SRC_DIR" ]; then
  echo "error: src directory does not exist."
  exit 1
fi

if [[ "$DST_DIR" != *.xcassets ]]; then
  echo "warning: destination does not appear to be an .xcassets folder."
fi

mkdir -p "$DST_DIR"

for file in "$SRC_DIR"/*.png; do
  [ -e "$file" ] || continue

  filename=$(basename "$file" .png)
  imageset_dir="$DST_DIR/${filename}.imageset"

  mkdir -p "$imageset_dir"

  cp "$file" "$imageset_dir/$filename.png"

  cat > "$imageset_dir/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "$filename.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

  echo "Added $filename to assets"
done

echo ""
read -rp "do you want to delete the original PNGs in '$SRC_DIR'? (y/N): " CONFIRM_DELETE

if [[ "$CONFIRM_DELETE" =~ ^[Yy]$ ]]; then
  rm "$SRC_DIR"/*.png
  echo "deleted pngs from $SRC_DIR"
else
  echo "okay"
fi