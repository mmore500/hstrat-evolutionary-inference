#!/usr/bin/env sh

set -e

# adapted from https://stackoverflow.com/a/73740277
gs -o /tmp/onlytxt.pdf -sDEVICE=pdfwrite -dFILTERVECTOR -dFILTERIMAGE "${1}"
gs -o /tmp/graphics.pdf -sDEVICE=pdfimage24 -dFILTERTEXT -r600 \
  -dDownScaleFactor=1 "${1}"
pdftk /tmp/graphics.pdf multistamp /tmp/onlytxt.pdf output "${2}"
rm /tmp/onlytxt.pdf /tmp/graphics.pdf
