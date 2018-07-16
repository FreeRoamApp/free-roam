#!/bin/sh
[ -z "$NODE_ENV" ] && export NODE_ENV=development

node_modules/gulp/bin/gulp.js dev
