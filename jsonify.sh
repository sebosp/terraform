#!/bin/bash
# Requirements: srcDir must be one and only one.
# Issues:
# - Does not support several source Dirs.
# - May not work properly with file/dir names with spaces
set -e
srcDir=$1
targetDir=$2
if [[ ! -d $srcDir ]]; then
  >&2 echo "Source directory does not exist. Bailing."
  exit 1;
fi
if [[ -d $targetDir ]]; then
  >&2 echo "Target directory exists. Bailing."
  exit 1;
fi
echo "Creating target directory $targetDir"
mkdir -p $targetDir
while read fileName; do
  curTargetFile=$(echo "$fileName"|sed "s|^${srcDir}|${targetDir}|;s|\.ya*ml$|\.json|")
  curTargetDir=$(dirname $curTargetFile);
  mkdir -p $curTargetDir
  echo "Jsonifying to $curTargetFile"
  ruby -ryaml -rjson -e "puts JSON.pretty_generate(YAML.load_file('$fileName'))" > $curTargetFile
done < <(find $srcDir -type f -regex '^.*\.ya*ml')
