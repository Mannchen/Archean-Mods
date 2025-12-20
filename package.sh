#!/usr/bin/env bash

vendor="MANNCHEN"
project_dir=$(dirname "$0")
output_dir="$project_dir/out"

packages="./
${vendor}_infinite
${vendor}_clock
${vendor}_valvehandle
${vendor}_airtightdoor
"

if [ -d "$output_dir" ]; then 
	echo "  rm -rf \"$output_dir\""
	rm -rf "$output_dir"
fi
mkdir "$output_dir"


for package in $packages; do
	packagename="$(basename "$package")"
	[ "$packagename" = "." ] && packagename="_All-mods"
	package_dir=$(realpath -m --relative-to=./ "$project_dir/$package")
	package_output_dir="$output_dir/$packagename"
	package_zip="$project_dir/Packaged_Zips/$packagename.zip"

	echo "  packaging '$packagename' ($package_dir)"
	mkdir "$package_output_dir"

	search_dirs=$(find "$package_dir" -type d  -regex "\(.+/\..+\|$package_dir/out\)" -prune -false -or -type d -regextype grep -regex "\(.*\|^\)${vendor}_[[:lower:][:digit:]]\{3,12\}")

	changes=""

	for mod_dir in $search_dirs; do
		if [ -d "$mod_dir/components" ]; then
			mod_name=$(basename "$mod_dir")
			echo "  Found mod: '$mod_name' ($mod_dir)"

			mod_output_dir="$package_output_dir/$mod_name"
			mkdir "$mod_output_dir"

			# components
			component_dirs=$(find "$mod_dir/components" -mindepth 1 -type d \( ! -regex '.+/\..+' \))
			[ -n "$component_dirs" ] && mkdir "$mod_output_dir/components"
			for dir in $component_dirs; do
				name=$(basename "$dir")
				if [ -f "$dir/$name.bin" -a -f "$dir/$name.gltf" -a -f "$dir/$name.ini" ]; then

					# is component
					echo "  Found component: '$dir'"
					component_output_dir="$mod_output_dir/components/$name"
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
					# TODO: add files created for sharp edges

					# add all xc files
					xenoncode_files=$(find "$dir" -type f -name "*.xc") 
					for xc_file in $xenoncode_files; do
						cp "$xc_file" "$component_output_dir/"
						[ "$xc_file" -nt "$package_zip" ] && changes="yes"
					done
				else
					echo "'$dir' is not a component."
				fi
			done

			# config
			if [ -f "$mod_dir/config.yaml" ]; then
				cp "$mod_dir/config.yaml" "$mod_output_dir/config.yaml"
				[ "$mod_dir/config.yaml" -nt "$package_zip" ] && changes="yes"
			fi
		fi
	done

	if [ -n "$changes" ]; then
		echo "  Zipping '$package_zip' ($package_output_dir)"

		abs_zip_path=$(realpath -E "$package_zip")
		pushd "$package_output_dir" >/dev/null
		zip --filesync -r "$abs_zip_path" "./"
		popd >/dev/null
	else
		echo "  No changes in '$packagename'. skipping zipping"
	fi

done

echo "  Done."

