#!/bin/bash
set -ex

# Give a path with images, it crops its upper 40px, (iOS status bar) and stores the result to out_dir
function cropOriginalRefs {

  in_dir=$1
  out_dir=$2

  # Clearing out_dir
  if [[ -d $out_dir ]] ; then
    rm -r $out_dir
  fi

  mkdir $out_dir

  echo "-- Start cropping.."
  # For each image, we remove the first 40 pixels (iOS status bar)
  for original_path in $in_dir/*.png
  do
      name=$(basename "$original_path")
      magick convert "${original_path}" -gravity north -chop 0x40 "${out_dir}/${name}"
  done
  echo "-- Cropping finished!"
}

# Helper method to check if element exists in a list
function containsElement {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Given a path with expected preloaded screenshtos (ref_dir) and a path of newly generated screenshots (new_dir), we generate a set of images diff report to out_dir
# diffignore_path is used as a way to ignore images that will likely not be exactly the same, because of different timestamps, etc
function imageDiff {

  ref_dir=$1
  new_dir=$2
  out_dir=$3
  diffignore_path=$4

  diff_path=$out_dir/diffs

  # Clearing folder
  if [[ -d $diff_path ]] ; then
    echo "-- Clearing diffs folder.."
    rm -r $diff_path
  fi

  mkdir $diff_path

  echo "-- Starting images diff.."
  same_array=()
  similar_array=()
  ignored_array=()
  different_array=()
  not_found_array=()
  similar_ignored_array=()

  # Reading ignore diff file
  while IFS='' read -r line || [[ -n "$line" ]]; do
    similar_to_ignore_array+=("$line")
    echo $line
  done < $diffignore_path

  # Iterating over refs to check how similar are to the new ones
  for ref_path in $ref_dir/*.png
  do

      name=$(basename "$ref_path")
      new_path=$new_dir/$name
      diff_file_path=$diff_path/$name

      if [[ -f $new_path ]] ; then

          set +e
          result=$(magick compare -metric RMSE -subimage-search "${new_path}" "${ref_path}" "${diff_file_path}"; echo $?)
          set -e
          # echo $result
          filename="${diff_file_path%.*}"
          extension="${diff_file_path##*.}"
          if [ $result -eq 0 ] ; then
              same_array+=("$new_path")
              # When files are the same, no need to generate diffs
              rm "${filename}"-0."${extension}"
              rm "${filename}"-1."${extension}"
          elif [ $result -eq 1 ] ; then

            set +e
            is_ignored=$(containsElement "${name}" "${similar_to_ignore_array[@]}"; echo $?)
            set -e
            if [ $is_ignored -eq 0 ] ; then
              ignored_array+=("$new_path")
            else
              similar_array+=("$new_path")
            fi
            # Removing empty generated file
            rm "${filename}"-1."${extension}"

          else
              different_array+=("$new_path")
          fi

      else
        # Expected image doesn't exist
        not_found_array+=("$new_path")
      fi
  done

  # Printed report
  echo "=====SCREENSHOTS DIFF RESULTS====="
  echo "-- SAME FILES: ${#same_array[@]}"
  echo "-- IGNORED FILES: ${#ignored_array[@]}"
  echo "-- SIMILAR FILES: ${#similar_array[@]} (See differences in ./diffs folder)"
  echo "-- DIFFERENT FILES: ${#different_array[@]} (Too different to generate diff pngs)"
  for different_path in "${different_array[@]}"
  do
      echo "${different_path}"
  done
  echo "-- NOT FOUND FILES: ${#not_found_array[@]}"
  for not_found_path in "${not_found_array[@]}"
  do
      echo "${not_found_path}"
  done

  # Step returned env var summary report
  envman add --key DIFF_SUMMARY --value "Diff Summary:
  Ignored ${#ignored_array[@]}
  Similar ${#similar_array[@]}
  Different ${#different_array[@]}
  Not Found ${#not_found_array[@]}"
}

# MAIN SCRIPT

if [ -z "${reference_screenshots_url}" ] ; then
  echo " [!] reference_screenshots_url not found"
  exit 1
fi

if [ -z "${new_screenshots_path}" ] ; then
  echo " [!] new_screenshots_path not found"
  exit 1
fi

if [ -z "${language}" ] ; then
  echo " [!] language not found"
  exit 1
fi

# Cloning into a folder that has files already, fails.
# On MacOSX usually we have the .DS_Store file that makes it fail
git clone $reference_screenshots_url tmp_clone
mv tmp_clone/* .
rm -r -f tmp_clone

new_screenshots=${new_screenshots_path}/${language}
cropped_refs_path=./cropped_refs
diffignore_path=${language}/diffignore

cropOriginalRefs $language $cropped_refs_path
imageDiff $cropped_refs_path $new_screenshots $new_screenshots_path $diffignore_path
