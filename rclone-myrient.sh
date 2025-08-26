#!/usr/bin/env bash
#
# USAGE: rclone-myrient.sh [options]
#
# shellcheck disable=SC2065,SC2220

function echo () {
  builtin echo '[*]:' "$@"
}

while getopts "b:c:f:s:t:" opt
do
  case $opt in
    b) rclone_bin=$OPTARG ;;
    c) rclone_config=$OPTARG ;;
    f) rclone_yaml=$OPTARG ;;
    s) rclone_shyaml=$OPTARG ;;
    t) rclone_transfer=$OPTARG ;;
  esac
done

RCLONE_BIN=${rclone_bin-/usr/bin/rclone}
RCLONE_CONFIG=${rclone_config-rclone-myrient.conf}
RCLONE_SHYAML=${rclone_shyaml-/usr/bin/shyaml}
RCLONE_TRANSFER=${rclone_transfer-copy}
RCLONE_YAML=${rclone_yaml-rclone-myrient.yaml}

for rclone_myrient_opt in \
  ${RCLONE_BIN} \
  ${RCLONE_CONFIG} \
  ${RCLONE_SHYAML} \
  ${RCLONE_YAML}
do
  if [[ ! -f "${rclone_myrient_opt}" ]]
  then
    echo "ERROR: Unable to locate ${test}, exiting."
    exit 1
  fi
done

rclone_myrient_len=$("${RCLONE_SHYAML}" get-length rclone_myrient < "${RCLONE_YAML}" 2>/dev/null)

if [[ -z "${rclone_myrient_len}" ]] || [[ ! "${rclone_myrient_len}" -gt 0 ]]
then
  echo "ERROR: The rclone myrient list is empty, exiting."
  exit 1
fi

for i in $(seq 0 $((rclone_myrient_len - 1)))
do

  rclone_myrient_continue=0
  for gv in \
    name \
    destination \
    options \
    sources
  do
    rclone_myrient_element=$("${RCLONE_SHYAML}" get-value "rclone_myrient.${i}.${gv}" < "${RCLONE_YAML}" 2>/dev/null)
    if [[ -z "${rclone_myrient_element}" ]]
    then
      echo "WARNING: Missing key/value pair rclone_myrient.${i}.${gv}, skipping."
      rclone_myrient_continue=$((rclone_myrient_continue + 1))
    fi
  done
  [[ "${rclone_myrient_continue}" -gt 0 ]] && continue

  name=$("${RCLONE_SHYAML}" get-value "rclone_myrient.${i}.name" < "${RCLONE_YAML}")
  destination=$("${RCLONE_SHYAML}" get-value "rclone_myrient.${i}.destination" < "${RCLONE_YAML}")
  options=$("${RCLONE_SHYAML}" get-values "rclone_myrient.${i}.options" < "${RCLONE_YAML}" | tr '\n' ' ')
  sources=$("${RCLONE_SHYAML}" get-length "rclone_myrient.${i}.sources" < "${RCLONE_YAML}")

  [[ -f "filters/${name}.filter" ]] && filter_from="filters/${name}.filter" || filter_from="filters/all.filter"

  for s in $(seq 0 $((sources - 1)))
  do

    [[ "${s}" -eq 0 ]] && builtin echo

    source=$("${RCLONE_SHYAML}" get-value "rclone_myrient.${i}.sources.${s}" < "${RCLONE_YAML}")

    echo "SOURCE      -> ${source}"
    echo "DESTINATION -> ${destination}"
    echo "FILTER FROM -> ${filter_from}"
    echo "OPTIONS     -> ${options}"
    builtin echo

    "${RCLONE_BIN}" mkdir "${destination}"

    # shellcheck disable=SC2086
    "${RCLONE_BIN}" "${RCLONE_TRANSFER}" \
      --config "${RCLONE_CONFIG}" \
      --filter-from "${filter_from}" \
      ${options} \
      "${source}" \
      "${destination}"

  done
done
