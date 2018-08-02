#!/bin/bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT=$(git rev-parse HEAD)
LAST_TAG=$(git tag | sort -V -r | sed '1q;d')

if [ -z $LAST_TAG ]; then
  ./node_modules/gulp/bin/gulp.js dist
  exit 0
fi

LAST_TAG_COMMIT=$(git show-ref --tags | grep $LAST_TAG | cut -d ' ' -f 1)

if [ "$CURRENT_COMMIT" = "$LAST_TAG_COMMIT" ]; then
  LAST_TAG=$(git tag | sort -V -r | sed '2q;d')
fi

if [ -z $LAST_TAG ]; then
  ./node_modules/gulp/bin/gulp.js dist
  exit 0
fi

# echo "building last tag $LAST_TAG"
# git checkout $LAST_TAG
# ./node_modules/gulp/bin/gulp.js dist
#
# echo "saving last tag build"
# mkdir ./_tmp_dist
# cp -r ./dist/* ./_tmp_dist

echo "building current branch"
git checkout $CURRENT_BRANCH

source ../padlock/kubernetes/namespaces/production/env.sh
NODE_ENV=production ./node_modules/gulp/bin/gulp.js dist

# echo "restoring last tag dist"
# cp -r ./dist/* ./_tmp_dist
# cp -r ./_tmp_dist/* ./dist
# rm -r ./_tmp_dist
