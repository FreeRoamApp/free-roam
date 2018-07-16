#!/bin/bash
export NODE_ENV=production

# replacements necessary for serviceworker. bundle replacements are done before cdn in dist
paths_dist=`./node_modules/coffee-script/bin/coffee -e "process.stdout.write require('./gulp_paths').dist"`

if [ ! -d $paths_dist ]; then
  echo "./dist directory not found. make sure to run 'npm run dist' beforehand"
  exit 1
fi

if [ -d "$paths_dist/backup" ]; then
  # Restore js from previous build
  echo "restoring backup dist files"
  cp $paths_dist/backup/*.js $paths_dist/

else
  # Backup js files before replacing
  mkdir -p $paths_dist/backup
  echo "backing up js files before replacing env"
  cp $paths_dist/*.js $paths_dist/backup/
fi

# Replace process.env.* with environment variable
while read -d $'\0' -r file; do
  echo "replacing environment variables in $file"
  while read line; do
    if [[ $line =~ process\.env\.([A-Z0-9_]+) ]]; then
      env_name="${BASH_REMATCH[1]}"
      env_string=$(echo $(eval "echo \$$env_name") | sed -e 's/[\/&]/\\&/g')
      if [ -z $env_string ]; then
        env_value="undefined"
      else
        env_value="'$env_string'"
      fi
      echo "replacing $env_name with $env_value"
      sed -i.bak s/process\.env\.$env_name/$env_value/g $file
    fi
  done < <(grep -o "process\.env\.[A-Z0-9_]\+" $file | uniq)
done < <(find $paths_dist -maxdepth 1 -iname '*.js' -print0)

./node_modules/coffee-script/bin/coffee ./bin/free_roam_server.coffee
