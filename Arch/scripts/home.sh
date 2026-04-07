#!/bin/bash

CONF_DIR="${HOME}/arch/scripts/conf"
source "${CONF_DIR}/files.conf"

delete_files() {
    echo_color BLUE "Checking DELETE_FILES array..."
    if [[ -z "${DELETE_FILES+x}" || ${#DELETE_FILES[@]} -eq 0 ]]; then
        echo_color RED "Error: DELETE_FILES array is not defined or is empty"
        return 1
    fi

    for FILE in "${DELETE_FILES[@]}"; do
        if [ -e "${HOME}/${FILE}" ]; then
            echo_color BLUE "Deleting $FILE..."
            sudo rm -r -- "${HOME}/${FILE}" || echo_color RED "Error: Could not delete ${FILE}."
        fi
    done

    return 0
}

create_files() {
    echo_color BLUE "Checking KEEP_FILES array..."
    if [[ -z "${KEEP_FILES+x}" || ${#KEEP_FILES[@]} -eq 0 ]]; then
        echo_color RED "Error: KEEP_FILES array is not defined or is empty."
        return 1
    fi

    for FILE in "${KEEP_FILES[@]}"; do
        FULL_PATH="${HOME}/${FILE}"
        if [[ "${FILE}" == */ ]]; then
            if [ ! -d "${FULL_PATH}" ]; then
                echo_color BLUE "Creating ${FILE}..."
                mkdir -p -- "${FULL_PATH}" || echo_color RED "Error: Could not create ${FILE}."
            fi
        else
            PARENT_DIR=$(dirname "${FULL_PATH}")
            if [ ! -d "${PARENT_DIR}" ]; then
                mkdir -p -- "${PARENT_DIR}" || echo_color RED "Error: Could not create ${FILE}."
            fi
            if [ ! -f "${FULL_PATH}" ]; then
                echo_color BLUE "Creating ${FILE}..."
                touch -- "${FULL_PATH}" || echo_color RED "Error: Could not create ${FILE}."
            fi
        fi
    done

    return 0
}

link_files() {
    echo_color BLUE "Checking DOTFILES array..."
    if [[ -z "${DOTFILES+x}" || ${#DOTFILES[@]} -eq 0 ]]; then
        echo_color RED "Error: DOTFILES array is not defined or is empty."
        return 1
    fi

    echo_color BLUE "Creating symbolic links..."
    for DOTFILE in "${DOTFILES[@]}"; do
        SRC="" TGT=""
        read -r SRC TGT <<< "${DOTFILE}"
        [[ -z "${TGT}" ]] && TGT="${SRC}"
        
        SOURCE="${HOME}/arch/dotfiles/${SRC}"
        TARGET="${TGT}"
        TARGET_DIR=$(dirname "${TARGET}")
        
        echo_color BLUE "Linking ${TARGET}..."
        if [[ ! -d "${TARGET_DIR}" ]]; then
            echo_color BLUE "Creating directory: ${TARGET_DIR}"
            mkdir -p -- "${TARGET_DIR}" || sudo mkdir -p -- "${TARGET_DIR}" || { 
                echo_color RED "Error: Could not create directory ${TARGET_DIR}."
                return 1
            }
        fi
        sudo rm -rf -- "${TARGET}"
        ln -sf -- "${SOURCE}" "${TARGET}" 2>/dev/null || sudo ln -sf -- "${SOURCE}" "${TARGET}" || {
            echo_color RED "Error: Could not link ${TARGET}."
            return 1
        }
    done

    hyprctl reload >/dev/null 2>&1 || echo_color YELLOW "Hyprctl not found."

    return 0
}

home_main() {
    starting "HOME SETUP"

    if ! delete_files; then
        failed "DELETING FILES"
    fi

    if ! create_files; then
        failed "CREATING FILES"
    fi

    if ! link_files; then
        failed "LINKING FILES"
    fi

    complete "HOME SETUP"
    
    return 0
}