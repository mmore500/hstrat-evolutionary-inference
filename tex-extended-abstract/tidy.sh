#!/bin/bash

shopt -s globstar

./script/bibtex-tidy.sh

for file in **/*.tex; do
  echo "${file}"
  sed -i '/\\caption{[^%]/s/\\caption{/&%\n/' "${file}"
  sed -i -E 's/([^[:blank:]])[[:blank:]]+/\1 /g' "${file}"
  sed -i -E 's/([^%[:space:]])[[:space:]]*\\label\{/\1\n\\label{/g' "${file}"
  latexindent -w -s -l="$(realpath latexindent.yaml)" -m "${file}"
done
