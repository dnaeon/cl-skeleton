#!/usr/bin/env bash
#
# Utility script for creating new projects using a skeleton
#

set -e

_SCRIPT_NAME="${0##*/}"
_SCRIPT_DIR=$( dirname `readlink -f -- "${0}"` )

# Files with the following extension are considered templates and will
# be expanded
_TEMPLATE_SUFFIX=${TEMPLATE_SUFFIX:-".tmpl"}

# Display an INFO message
# $1: Message to display
function _msg_info() {
    local _msg="${1}"

    echo "[${_SCRIPT_NAME}] INFO: ${_msg}"
}

# Display an ERROR message
# $1: Message to display
# $2: Exit code
function _msg_error() {
    local _msg="${1}"
    local _rc=${2}

    echo "[${_SCRIPT_NAME}] ERROR: ${_msg}"

    if [[ ${_rc} -ne 0 ]]; then
        exit ${_rc}
    fi
}

# Prints usage info and exits
function _usage() {
    echo "${_SCRIPT_NAME} [expand|dry-run]"
    exit 64  # EX_USAGE
}

# Expands any template files
#
# $1: execute in dry-run, if set to true
function _expand_templates() {
    local _dry_run_mode="${1}"

    for _tmpl_file in $( find . -name "*${_TEMPLATE_SUFFIX}" ); do
        _expanded=$( echo "${_tmpl_file}" | sed -e "s|${_TEMPLATE_SUFFIX}||g" -e "s|cl-skeleton|${PROJECT_NAME}|g" )
        _msg_info "Expanding template file ${_tmpl_file} ..."
        if [ "${_dry_run_mode}" == "false" ]; then
            cp --preserve=mode "${_tmpl_file}" "${_expanded}"
            envsubst < "${_tmpl_file}" > "${_expanded}"
        fi
        _msg_info "Deleting template file ${_tmpl_file} ..."

        if [ "${_dry_run_mode}" == "false" ]; then
            rm -f "${_tmpl_file}"
        fi
    done
}

# Main entrypoint
function _main() {
    local _cmd="${1}"

    if [[ $# -lt 1 ]]; then
        _usage
    fi

    local _project_vars="${_SCRIPT_DIR}/project-vars.env"

    # Source project variables, if any.
    if [ ! -f "${_project_vars}" ]; then
        _msg_error "Skeleton variables not found: ${_project_vars}" 1

    fi

    set -a
    source "${_project_vars}"
    set +a

    case "${_cmd}" in
        expand)
            _expand_templates "false"
            ;;
        dry-run)
            _expand_templates "true"
            ;;
        *)
            _usage
            ;;
    esac

    _msg_info "Done"
}

_main $*
