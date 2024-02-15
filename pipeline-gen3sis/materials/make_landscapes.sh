#!/bin/bash

set -e

cd "$(dirname "$0")"


git clone https://github.com/project-gen3sis/Simulations.git || :
(cd Simulations; git checkout 8ce6b88a6cd388f4cb4d963bb807ef91633385c6)

rm -rf landscapes
mkdir -p landscapes

singularity run docker://ghcr.io/mmore500/gen3sis@sha256:ec5c901d454e6cbee7e02f5675006ddd38c8c4c94a33027d963779216c9c7b80 Rscript make_landscapes.R

cd landscapes

ln -s waterignore ecology
ln -s waterignore plain
ln -s waterbarrier spatial_ecology
ln -s waterbarrier spatial_plain
