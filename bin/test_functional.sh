#!/bin/bash
export NODE_ENV=development
export REMOTE_SELENIUM=1
trap "exit" SIGINT # allow ctrl-c to exit

declare -a browsers=("chrome" "firefox" "safari" "internet explorer" "android")

for i in "${browsers[@]}"
do
  echo "Running functional tests in $i"
  SELENIUM_BROWSER="$i" node_modules/gulp/bin/gulp.js test:functional
done
