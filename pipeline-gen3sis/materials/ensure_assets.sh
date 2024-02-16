#!/bin/bash

set -e
set -u

if [ ! -d "Simulations" ]; then
    echo "Simulations directory for gen3sis assets not found, cloning it"
    git clone https://github.com/project-gen3sis/Simulations.git
fi
(cd Simulations; git checkout 8ce6b88a6cd388f4cb4d963bb807ef91633385c6) || (rm -rf Simulations; ./ensure_assets.sh)
