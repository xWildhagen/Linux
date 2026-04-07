#!/usr/bin/env bash

CONF_DIR="${HOME}/arch/scripts/conf"
source "${CONF_DIR}/colors.conf" || true

# echo_color COLOR "MESSAGE"
echo_color() {
    local COLOR="$1"
    local MESSAGE="$2"
    
    echo -e "${!COLOR}${MESSAGE}${NC}"

    return 0
}

# echo_dashes COLOR WIDTH
echo_dashes() {
    local COLOR="$1"
    local WIDTH="$2"

    echo -e "${!COLOR}$(printf "%*s" "${WIDTH}" "" | tr ' ' '-')${NC}"

    return 0
}

# Usage: read_input COLOR "MESSAGE" VARIABLE
read_input() {
    local COLOR="$1"
    local MESSAGE="$2"
    local VARIABLE="$3" 

    echo -e -n "${!COLOR}${MESSAGE}${NC}"

    if [[ -n "$VARIABLE" ]]; then
        read -r "$VARIABLE"
    else
        read -r temp_input
    fi

    echo_dashes BLUE 50

    return 0
}

starting() {
    clear
    echo_dashes BLUE 50
    echo_color BLUE "STARTING $*"
    echo_dashes BLUE 50

    return 0
}

complete() {
    echo_dashes BLUE 50
    echo_color GREEN "$* COMPLETE"
    echo_dashes BLUE 50
    read_input GREEN "PRESS ENTER TO CONTINUE..."

    return 0
}

warning() {
    echo_dashes BLUE 50
    echo_color YELLOW "$* WARNING"
    echo_dashes BLUE 50

    return 0
}

failed() {
    echo_dashes BLUE 50
    echo_color RED "$* FAILED"
    echo_dashes BLUE 50
    read_input RED "PRESS ENTER TO CONTINUE..."

    return 0
}
