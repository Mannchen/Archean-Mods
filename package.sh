#!/usr/bin/env bash

project_dir=$(dirname "$0")

output_dir="$project_dir/Archean_mod"

if [ -f "$project_dir/Mannchen-mods.zip" ]; then
	echo "rm \"$project_dir/Mannchen-mods.zip\""
	rm "$project_dir/Mannchen-mods.zip"
fi
if [ -d "$output_dir" ]; then 
	echo "rm -rf \"$output_dir\""
	rm -rf "$output_dir"
fi

mkdir "$output_dir"
mkdir "$output_dir/components"

echo "packaging to '$output_dir'"

search_dirs=$(find "$project_dir" -type d -regex '.*/\..*' -prune -false -or -type d \( ! -regex '.*/\..*' \))

for dir in $search_dirs; do
	name=$(basename "$dir")
	if [ -f "$dir/$name.bin" -a -f "$dir/$name.gltf" -a -f "$dir/$name.ini" ]; then
		# is component
		echo "Found: '$dir'"
		component_output_dir="$output_dir/components/$name"
		mkdir "$component_output_dir"
		cp "$dir/$name.bin"  "$component_output_dir/$name.bin"
		cp "$dir/$name.gltf" "$component_output_dir/$name.gltf"
		cp "$dir/$name.ini"  "$component_output_dir/$name.ini"
		[ -f "$dir/$name.md"  ] && cp "$dir/$name.md"  "$component_output_dir/$name.md"
		[ -f "$dir/$name.png" ] && cp "$dir/$name.png" "$component_output_dir/$name.png"
		[ -f "$dir/main.xc"   ] && cp "$dir/main.xc"   "$component_output_dir/main.xc"
	fi
done

if [ -f "$project_dir/config.yaml" ]; then
	echo "Found config.yaml"
	cp "$project_dir/config.yaml" "$output_dir/config.yaml"
fi

echo "Zipping..."
zip -r "$project_dir/Mannchen-mods.zip" "$output_dir"

echo "Done."

