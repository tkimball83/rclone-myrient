#!/usr/bin/env bash
#
# USAGE: rclone-myrient.sh [options]
#
# shellcheck disable=SC2220

function debug () {
  builtin echo '[*]:' "$@"
}

function get_length () {
  local key="${1}"
  local length

  length=$("${RCLONE_SHYAML}" get-length "${key}" < "${RCLONE_YAML}" 2>/dev/null)

  echo "${length}"
}

function get_type () {
  local key="${1}"
  local type

  type=$("${RCLONE_SHYAML}" get-type "${key}" < "${RCLONE_YAML}" 2>/dev/null)

  if [[ "${type}" == 'str' ]]
  then
    query=get-value
  elif [[ "${type}" == 'sequence' ]]
  then
    query=get-values
  else
    query=
  fi

  echo "${query}"
}


function get_value () {
  local key="${1}"
  local query
  local value

  query=$(get_type "${key}")

  if [[ -z "${query}" ]]
  then
    value=
  else
    value=$("${RCLONE_SHYAML}" "${query}" "${key}" < "${RCLONE_YAML}" | tr '\n' ' ' 2>/dev/null)
  fi

  echo "${value}"
}

while getopts "b:c:df:s:t:" opt
do
  case $opt in
    b) rclone_bin=$OPTARG ;;
    c) rclone_config=$OPTARG ;;
    d) rclone_debug=true ;;
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

for opt in ${RCLONE_BIN} ${RCLONE_CONFIG} \
           ${RCLONE_SHYAML} ${RCLONE_YAML}
do
  if [[ ! -f "${opt}" ]]
  then
    echo "ERROR: Unable to locate ${opt}, exiting."
    exit 1
  fi
done

yaml_length=$(get_length rclone_myrient)

if [[ -z "${yaml_length}" ]] || [[ ! "${yaml_length}" -gt 0 ]]
then
  echo "ERROR: The rclone myrient list is empty, exiting."
  exit 1
fi

for i in $(seq 0 $((yaml_length - 1)))
do

  declare -A map
  for key in name destination options sources
  do
    map[${key}]=$(get_value "rclone_myrient.${i}.${key}")
    if [[ -z "${map[${key}]}" ]]
    then
      echo "ERROR: Missing key/value pair rclone_myrient.${i}.${key}, skipping."
      continue 2
    fi
  done

  if [[ -f "filters/${map['name']}.filter" ]]
  then
    filter_from="${map['name']}.filter"
  else
    filter_from="all.filter"
  fi

  map['sources']=$(get_length "rclone_myrient.${i}.sources")

  for s in $(seq 0 $((map['sources'] - 1)))
  do
    map['source']=$(get_value "rclone_myrient.${i}.sources.${s}")

    if [[ "${rclone_debug}" = true ]]
    then
      [[ "${s}" == 0 ]] && echo
      debug "SOURCE      -> ${map['source']}"
      debug "DESTINATION -> ${map['destination']}"
      debug "FILTER FROM -> ${filter_from}"
      debug "OPTIONS     -> ${map['options']}"
      echo
    fi

    "${RCLONE_BIN}" mkdir "${map['destination']}"

    # shellcheck disable=SC2086
    "${RCLONE_BIN}" "${RCLONE_TRANSFER}" \
      --config "${RCLONE_CONFIG}" \
      --filter-from "filters/${filter_from}" \
      ${map['options']} \
      "${map['source']}" \
      "${map['destination']}"

  done
done
