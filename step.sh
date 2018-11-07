#!/bin/bash
set -ex

echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

echo $BITRISE_SOURCE_DIR
echo $BITRISE_DEPLOY_DIR
echo $REFERENCE_SCREENSHOTS_URL
echo $NEW_SCREENSHOTS_PATH
echo $DIFF_LANGUAGE

# Is this necessary?
rm -r -f original_refs
rm -r -f refs
rm -r -f new
rm -r -f tmp_clone

git clone $REFERENCE_SCREENSHOTS_URL tmp_clone
mv tmp_clone/* .
rm -r -f tmp_clone

new_screenshots=${NEW_SCREENSHOTS_PATH}/${DIFF_LANGUAGE}

sh image_diff.sh $DIFF_LANGUAGE $new_screenshots $NEW_SCREENSHOTS_PATH

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
