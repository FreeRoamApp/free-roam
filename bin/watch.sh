#!/bin/sh
export NODE_ENV=test

case $1 in
  phantom)
    GULP_COMMAND="watch:phantom"
  ;;
  server)
    GULP_COMMAND="watch:server"
  ;;
  functional)
    docker run -i --rm -p 4444:4444 selenium/standalone-chrome:2.48.2 >> /dev/null &
    GULP_COMMAND="watch:functional"
  ;;
  *)
    GULP_COMMAND="watch"
  ;;
esac

node_modules/gulp/bin/gulp.js $GULP_COMMAND
