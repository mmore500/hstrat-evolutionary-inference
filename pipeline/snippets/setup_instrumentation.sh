#!/bin/bash

set -e
set -o nounset
shopt -s globstar

err() {
    echo "Error occurred:"
    awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=$1 $0
}
trap 'err $LINENO' ERR

python3 -c "import hstrat; print('hstrat version', hstrat.__version__)"
