#!/bin/bash

repos=( 
  "."
  "../pct-data"
  "../pct-bigdata" 
  "../pct-shiny"
)

echo "Checking" ${#repos[@]} "repositories for updates"

for repo in "${repos[@]}"
do
  echo "updating" ${repo}
  cd "${repo}"
  git pull
done