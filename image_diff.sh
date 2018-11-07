echo "-- Clearing diffs folder.."
rm -r ./diffs
mkdir ./diffs

echo "-- Starting images diff.."
same_array=()
similar_array=()
different_array=()
not_found_array=()

for ref_path in ./refs/*.png
do

    name=$(basename "$ref_path")
    new_path=./new/$name
    diff_path=./diffs/$name

    if [[ -f $new_path ]] ; then

        command="magick compare -metric RMSE -subimage-search $new_path $ref_path $diff_path"
        echo "-- Running: $command"
        magick compare -metric RMSE -subimage-search "${new_path}" "${ref_path}" "${diff_path}"
        result="$?"
        echo "$result"
        filename="${diff_path%.*}"
        extension="${diff_path##*.}"
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

echo "=====RESULTS====="
echo "SAME FILES: ${#same_array[@]}"
echo "SIMILAR FILES: ${#similar_array[@]} (See differences in ./diffs folder)"
echo "DIFFERENT FILES: ${#different_array[@]} (Too different to generate diff pngs)"
for different_path in "${different_array[@]}"
do
    echo $different_path
done
echo "NOT FOUND FILES: ${#not_found_array[@]}"
for not_found_path in "${not_found_array[@]}"
do
    echo $not_found_path
done

