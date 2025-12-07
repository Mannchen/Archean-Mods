#!/usr/bin/env bash

packages="./
Infinite
Clock
ValveHandle
"

project_dir=$(dirname "$0")
output_dir="$project_dir/out"

if [ -d "$output_dir" ]; then 
	echo "rm -rf \"$output_dir\""
	rm -rf "$output_dir"
fi
mkdir "$output_dir"


for package in $packages; do
	packagename=$(basename "$package")
	[ "$packagename" = "." ] && packagename="_All-mods"
	package_dir=$(realpath -m --relative-to=./ "$project_dir/$package")
	temp_dir="$output_dir/$packagename"
	package_zip="$project_dir/Packaged_Zips/$packagename.zip"

	if [ -f "$package_zip" ]; then
		echo "rm '$package_zip'"
		rm "$package_zip"
	fi

	mkdir "$temp_dir"
	echo "packaging '$packagename' ($package_dir)"

	search_dirs=$(find "$package_dir" -type d -regex '.*/\..*' -prune -false -or -type d \( ! -regex '.*/\..*' \))

	for dir in $search_dirs; do
		name=$(basename "$dir")
		if [ -f "$dir/$name.bin" -a -f "$dir/$name.gltf" -a -f "$dir/$name.ini" ]; then
			# is component
			echo "Found component: '$dir'"
			component_output_dir="$temp_dir/$name"
			mkdir "$component_output_dir"
			cp "$dir/$name.bin"  "$component_output_dir/$name.bin"
			cp "$dir/$name.gltf" "$component_output_dir/$name.gltf"
			cp "$dir/$name.ini"  "$component_output_dir/$name.ini"
			[ -f "$dir/$name.md"  ] && cp "$dir/$name.md"  "$component_output_dir/$name.md"
			[ -f "$dir/$name.png" ] && cp "$dir/$name.png" "$component_output_dir/$name.png"
			[ -f "$dir/main.xc"   ] && cp "$dir/main.xc"   "$component_output_dir/main.xc"
		fi
	done

	echo "Zipping '$package_zip' ($temp_dir)"
	abs_zip_path=$(realpath -E "$package_zip")
	pushd "$temp_dir" >/dev/null
	zip -r "$abs_zip_path" "./"
	popd >/dev/null

done

# if [ -f "$project_dir/config.yaml" ]; then
# 	echo "Found config.yaml"
# 	cp "$project_dir/config.yaml" "$output_dir/config.yaml"
# fi

echo "Done."

