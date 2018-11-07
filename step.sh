#!/bin/bash
set -ex

echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

echo $BITRISE_SOURCE_DIR
echo $BITRISE_DEPLOY_DIR
echo $REFERENCE_SCREENSHOTS_URL
echo $NEW_SCREENSHOTS_PATH

# TODO Check $REFERENCE_SCREENSHOTS_URL and $NEW_SCREENSHOTS_PATH are valid

# Is this necessary?
rm -r -f original_refs
rm -r -f refs
rm -r -f new

git clone $REFERENCE_SCREENSHOTS_URL original_refs

mkdir refs
mkdir new

# cp ${NEW_SCREENSHOTS_PATH}/* new
cp ${BITRISE_DEPLOY_DIR}/en-US/* new

# Is there a better way to get the scripts?
cp ${BITRISE_SOURCE_DIR}/../crop_original_refs.sh .
cp ${BITRISE_SOURCE_DIR}/../image_diff.sh .
sh crop_original_refs.sh
sh image_diff.sh

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
