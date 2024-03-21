#!/bin/bash

# REVISION shouldd be set in script sourcing this one
echo "REVISION ${REVISION}"

module purge || :
module load GCCcore/10.2.0 Python/3.8.10 || :

ln -s "${HOME}/scratch" "/mnt/scratch/${USER}/" || :
TMPDIR_="${HOME}/scratch/tmp"
mkdir -p "${TMPDIR_}"

VENV_CACHE_PATH="/${TMPDIR_}/venv-${REVISION}"
echo "VENV_CACHE_PATH ${VENV_CACHE_PATH}"


if test -d "${VENV_CACHE_PATH}" && [[ -n "${REVISION}" ]]
then


echo "venv cache available at ${VENV_CACHE_PATH}"
VENV_PATH="${VENV_CACHE_PATH}"
source "${VENV_PATH}/bin/activate"

else

echo "no eligible venv cache available at ${VENV_CACHE_PATH}"
echo "maybe revision isn't set?"
VENV_PATH="$(mktemp -d "${TMPDIR_}/XXXXXX")"
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

echo "setting venv cache at ${VENV_CACHE_PATH}"
ln -s "${VENV_PATH}" "${VENV_CACHE_PATH}" || :

fi

python3 -c "import hstrat; print('hstrat version', hstrat.__version__)"
