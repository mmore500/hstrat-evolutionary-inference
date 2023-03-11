#!/bin/bash

# REVISION shouldd be set in script sourcing this one
echo "REVISION ${REVISION}"

module purge || :
module load GCCcore/10.2.0 Python/3.8.10 || :

VENV_PATH="$(mktemp -d)"
echo "VENV_PATH ${VENV_PATH}"

for try in {0..9}; do
  rm -rf "${VENV_PATH}"  \
  && python3 -m venv "${VENV_PATH}"  \
  && echo "venv created"  \
    \
  && source "${VENV_PATH}/bin/activate"  \
    \
  && python3 -m pip install -r "https://raw.githubusercontent.com/mmore500/hstrat-evolutionary-inference/${REVISION}/requirements.txt" \
  && break \
  || echo "venv setup failed (try ${try})"

  SLEEP_DURATION="$((RANDOM % 10 + 1))"
  echo "sleeping ${SLEEP_DURATION} then retrying"
  sleep "${SLEEP_DURATION}"
done

python3 -c "import hstrat; print('hstrat version', hstrat.__version__)"
