#!/usr/bin/env bash
#
# USAGE: rclone-myrient.sh [options]
#
# shellcheck disable=SC2065,SC2220

function get_kv () {
  local key="${1}"
  local type=$("${RCLONE_SHYAML}" get-type "${key}" < "${RCLONE_YAML}")

  if [[ "${type}" == 'str' ]]
  then
    value=$("${RCLONE_SHYAML}" get-value "${key}" < "${RCLONE_YAML}")
  else
    value=$("${RCLONE_SHYAML}" get-values "${key}" < "${RCLONE_YAML}" | tr '\n' ' ')
  fi

  echo "${value}"
}

function validate_opt () {
  local opt="${1}"

  [[ ! -f "${opt}" ]] && return 1 || return 0
}

function validate_kv () {
  local key="${1}"
  local value=$("${RCLONE_SHYAML}" get-value "${key}" < "${RCLONE_YAML}" 2>/dev/null)

  [[ -z "${value}" ]] && return 1 || return 0
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

for opt in ${RCLONE_BIN} ${RCLONE_CONFIG} ${RCLONE_SHYAML} ${RCLONE_YAML}
do
  validate_opt "${opt}"
  if [[ $? -eq 1 ]]
  then
    echo "ERROR: Unable to locate ${opt}, exiting."
    exit 1
  fi
done

yaml_length=$("${RCLONE_SHYAML}" get-length rclone_myrient < "${RCLONE_YAML}" 2>/dev/null)

if [[ -z "${yaml_length}" ]] || [[ ! "${yaml_length}" -gt 0 ]]
then
  echo "ERROR: The rclone myrient list is empty, exiting."
  exit 1
fi

for i in $(seq 0 $((yaml_length - 1)))
do
  for key in name destination options sources
  do
    validate_kv "rclone_myrient.${i}.${key}"
    if [[ $? -eq 1 ]]
    then
      echo "ERROR: Missing key/value pair rclone_myrient.${i}.${key}, skipping."
      continue 2
    fi
  done

  declare -A map
  for key in name destination options
  do
    map[${key}]=$(get_kv "rclone_myrient.${i}.${key}")
  done

  [[ -f "filters/${name}.filter" ]] && filter_from="${name}.filter" || filter_from="all.filter"

  sources=$("${RCLONE_SHYAML}" get-length "rclone_myrient.${i}.sources" < "${RCLONE_YAML}")

  for s in $(seq 0 $((sources - 1)))
  do
    [[ "${s}" -eq 0 ]] && echo

    source=$(get_kv "rclone_myrient.${i}.sources.${s}")

    echo "SOURCE      -> ${source}"
    echo "DESTINATION -> ${map['destination']}"
    echo "FILTER FROM -> ${filter_from}"
    echo "OPTIONS     -> ${map['options']}"
    echo

    "${RCLONE_BIN}" mkdir "${map['destination']}"

    # shellcheck disable=SC2086
    "${RCLONE_BIN}" "${RCLONE_TRANSFER}" \
      --config "${RCLONE_CONFIG}" \
      --filter-from "filters/${filter_from}" \
      ${map['options']} \
      "${source}" \
      "${map['destination']}"

  done
done
