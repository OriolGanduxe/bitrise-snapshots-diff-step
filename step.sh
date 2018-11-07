#!/bin/bash
set -ex

echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

echo $BITRISE_SOURCE_DIR
echo $BITRISE_DEPLOY_DIR
echo $REFERENCE_SCREENSHOTS_URL
echo $NEW_SCREENSHOTS_PATH

rm -r -f ./flo-screenshots
git clone $REFERENCE_SCREENSHOTS_URL
cd flo-screenshots
cp -r ../../new .
cp ../../crop_original_refs.sh .
cp ../../image_diff.sh .
sh crop_original_refs.sh
sh image_diff.sh

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
