#!/usr/bin/env bash

packages="./
Infinite
Clock
ValveHandle
AirtightDoor
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

	# if [ -f "$package_zip" ]; then
	# 	echo "rm '$package_zip'"
	# 	rm "$package_zip"
	# fi

	mkdir "$temp_dir"
	echo "packaging '$packagename' ($package_dir)"

	search_dirs=$(find "$package_dir" -type d -regex '.*/\..*' -prune -false -or -type d \( ! -regex '.*/\..*' \))

	changes=""

	for dir in $search_dirs; do
		name=$(basename "$dir")
		if [ -f "$dir/$name.bin" -a -f "$dir/$name.gltf" -a -f "$dir/$name.ini" ]; then
			# is component
			echo "Found component: '$dir'"
			component_output_dir="$temp_dir/$name"
			mkdir "$component_output_dir"
			cp "$dir/$name.bin" "$component_output_dir/$name.bin"
			[ "$dir/$name.bin" -nt "$package_zip" ] && changes="yes"
			cp "$dir/$name.gltf" "$component_output_dir/$name.gltf"
			[ "$dir/$name.gltf" -nt "$package_zip" ] && changes="yes"
			cp "$dir/$name.ini" "$component_output_dir/$name.ini"
			[ "$dir/$name.ini" -nt "$package_zip" ] && changes="yes"
			if [ -f "$dir/$name.md" ]; then
				cp "$dir/$name.md" "$component_output_dir/$name.md"
				[ "$dir/$name.md" -nt "$package_zip" ] && changes="yes"
			fi
			if [ -f "$dir/$name.png" ]; then
				cp "$dir/$name.png" "$component_output_dir/$name.png"
				[ "$dir/$name.png" -nt "$package_zip" ] && changes="yes"
			fi
			if [ -f "$dir/main.xc" ]; then
				cp "$dir/main.xc" "$component_output_dir/main.xc"
				[ "$dir/main.xc" -nt "$package_zip" ] && changes="yes"
			fi
		fi
	done

	if [ -n "$changes" ]; then
		echo "Zipping '$package_zip' ($temp_dir)"

		abs_zip_path=$(realpath -E "$package_zip")
		pushd "$temp_dir" >/dev/null
		zip --filesync -r "$abs_zip_path" "./"
		popd >/dev/null
	else
		echo "No changes in '$packagename'. skipping zipping"
	fi

done

# if [ -f "$project_dir/config.yaml" ]; then
# 	echo "Found config.yaml"
# 	cp "$project_dir/config.yaml" "$output_dir/config.yaml"
# fi

echo "Done."

