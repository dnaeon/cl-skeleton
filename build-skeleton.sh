#!/usr/bin/env bash
#
# Copyright (c) 2022 Marin Atanasov Nikolov <dnaeon@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer
#     in this position and unchanged.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

_SCRIPT_NAME="${0##*/}"
_SCRIPT_DIR=$( dirname `readlink -f -- "${0}"` )
_BASE_PROJECT_DIR="${_SCRIPT_DIR}"

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
    echo "Usage: ${_SCRIPT_NAME} expand /path/to/new/cl-project"
    exit 64  # EX_USAGE
}

# Copies the project files into the new target directory
#
# $1: Path to the new project
function _copy_project_files() {
    local _new_project_path="${1}"

    _msg_info "Creating new project in ${_new_project_path} ..."
    mkdir -p "${_new_project_path}"

    for _dir in $( find "${_BASE_PROJECT_DIR}" \
                        -maxdepth 1 \
                        -type d \
                        -and -not -path "${_BASE_PROJECT_DIR}" \
                        -and -not -path "${_BASE_PROJECT_DIR}/.git" \
                        -print ); do
        _msg_info "Copying directory $( basename ${_dir} )/ into ${_new_project_path}/"
        cp -a "${_dir}" "${_new_project_path}/"
    done

    for _file in $( find "${_BASE_PROJECT_DIR}" \
                         -maxdepth 1 \
                         -type f \
                         -not -name "project-vars.env" \
                         -and -not -name "project-literals.env" \
                         -and -not -name "build-skeleton.sh" \
                         -print ); do
        _msg_info "Copying file $( basename ${_file} ) into ${_new_project_path}/"
        cp --preserve=mode "${_file}" "${_new_project_path}/"
    done
}

# Expands any template files
#
# $1: Path to the new project
function _expand_templates() {
    local _new_project_path="${1}"
    local _oldpwd="${OLDPWD}"

    cd "${_new_project_path}"
    for _tmpl_file in $( find . -name "*${_TEMPLATE_SUFFIX}" ); do
        _expanded=$( echo "${_tmpl_file}" | sed -e "s|${_TEMPLATE_SUFFIX}||g" -e "s|cl-skeleton|${PROJECT_NAME}|g" )
        _msg_info "Expanding template ${_tmpl_file} into ${_expanded} ..."
        cp --preserve=mode "${_tmpl_file}" "${_expanded}"
        envsubst < "${_tmpl_file}" > "${_expanded}"

        _msg_info "Deleting template ${_tmpl_file} ..."
        rm -f "${_tmpl_file}"
    done

    cd "${_oldpwd}"
}

# Main entrypoint
function _main() {
    local _cmd="${1}"
    local _new_project_path="${2}"

    if [[ $# -lt 2 ]]; then
        _usage
    fi

    local _project_vars="${_SCRIPT_DIR}/project-vars.env"
    local _project_literals="${_SCRIPT_DIR}/project-literals.env"

    # Source project variables, if any.
    if [ ! -f "${_project_vars}" ]; then
        _msg_error "Skeleton variables not found: ${_project_vars}" 1
    fi

    set -a
    # Source project-specific variables
    source "${_project_vars}"
    # Source literals, if any
    if [ -f "${_project_literals}" ]; then
        source "${_project_literals}"
    fi
    set +a

    case "${_cmd}" in
        expand)
            _copy_project_files "${_new_project_path}"
            _expand_templates "${_new_project_path}"
            ;;
        *)
            _usage
            ;;
    esac

    _msg_info "Done"
}

_main $*
