echo "-- Clearing refs folder.."
rm -r ./refs
mkdir ./refs

cd refs
echo "-- Start cropping.."

for original_path in ../original_refs/*.png
do

    name=$(basename "$original_path")
    echo "name $name"

    command="magick convert $original_path -gravity north -chop 0x40 $name"
    echo "-- Running: $command"
    magick convert "${original_path}" -gravity north -chop 0x40 "${name}"

done

cd ..
