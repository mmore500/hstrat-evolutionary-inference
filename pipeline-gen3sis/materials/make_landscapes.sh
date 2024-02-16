#!/bin/bash

set -e

cd "$(dirname "$0")"

source ./IMAGE_URI.sh
./ensure_assets.sh

rm -rf landscapes
mkdir -p landscapes

singularity run "${IMAGE_URI}" Rscript make_landscapes.R

cd landscapes

ln -s waterignore ecology
ln -s waterignore plain
ln -s waterbarrier spatial_ecology
ln -s waterbarrier spatial_plain
