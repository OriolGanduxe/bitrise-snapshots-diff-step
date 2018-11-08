#!/bin/bash
set -ex

function cropOriginalRefs {

  in_dir=$1
  out_dir=$2

  if [[ -d $out_dir ]] ; then
    rm -r $out_dir
  fi

  mkdir $out_dir

  echo "-- Start cropping.."

  for original_path in $in_dir/*.png
  do

      name=$(basename "$original_path")
      magick convert "${original_path}" -gravity north -chop 0x40 "${out_dir}/${name}"
  done
  echo "-- Cropping finished!"

}

function imageDiff {

  ref_dir=$1
  new_dir=$2
  out_dir=$3
  tmp_refs_dir=$4

  diff_path=$out_dir/diffs

  if [[ -d $diff_path ]] ; then
    echo "-- Clearing diffs folder.."
    rm -r $diff_path
  fi

  mkdir $diff_path

  echo "-- Starting images diff.."
  same_array=()
  similar_array=()
  different_array=()
  not_found_array=()

  for ref_path in $tmp_refs_dir/*.png
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
              similar_array+=("$new_path")
              # Removing empty generated file
              rm "${filename}"-1."${extension}"
          else
              different_array+=("$new_path")
          fi

      else
          not_found_array+=("$new_path")
      fi
  done

  summary="=====RESULTS=====\n"
  summary+="SAME FILES: ${#same_array[@]}\n"
  summary+="SIMILAR FILES: ${#similar_array[@]} (See differences in ./diffs folder)\n"
  summary+="DIFFERENT FILES: ${#different_array[@]} (Too different to generate diff pngs)\n"
  for different_path in "${different_array[@]}"
  do
      summary+="${different_path}\n"
  done
  summary+="NOT FOUND FILES: ${#not_found_array[@]}\n"
  for not_found_path in "${not_found_array[@]}"
  do
      summary+="${not_found_path}\n"
  done

  echo $summary
  envman add --key DIFF_SUMMARY --value $summary
}

# MAIN SCRIPT

echo $BITRISE_SOURCE_DIR
echo $BITRISE_DEPLOY_DIR
echo $REFERENCE_SCREENSHOTS_URL
echo $NEW_SCREENSHOTS_PATH
echo $DIFF_LANGUAGE

# Cloning into a folder that has files already, fails.
# On MacOSX usually we have the .DS_Store file that makes it fail
git clone $REFERENCE_SCREENSHOTS_URL tmp_clone
mv tmp_clone/* .
rm -r -f tmp_clone

new_screenshots=${NEW_SCREENSHOTS_PATH}/${DIFF_LANGUAGE}
cropped_refs_path=./cropped_refs

cropOriginalRefs $DIFF_LANGUAGE $cropped_refs_path
imageDiff $DIFF_LANGUAGE $new_screenshots $NEW_SCREENSHOTS_PATH $cropped_refs_path

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
