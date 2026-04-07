#!/bin/bash

# Loop through all .sh files in the scripts directory and source them
for file in "${HOME}/arch/scripts/"*.sh; do
    source "$file"
done

main() {
    while true; do
        clear

        echo_dashes BLUE 50
        echo_color BLUE "MAIN MENU"
        echo_dashes BLUE 50

        echo_color BLUE "1) Start archinstall"
        echo_color BLUE "2) Start package installation"
        echo_color BLUE "3) Start home setup"
        echo_color BLUE "0) Quit"
        echo_dashes BLUE 50

        read_input PURPLE "ENTER OPTION: " OPTION

        case "$OPTION" in
        1)
            archinstall_main
            ;;
        2)
            packages_main
            ;;
        3)
            home_main
            ;;
        0|q|Q)
            echo_color GREEN "EXITING SCRIPT. GOODBYE!"
            echo_dashes BLUE 50
            break
            ;;
        *)
            read_input RED "INVALID OPTION. PRESS ENTER TO CONTINUE..."
            ;;
        esac
    done
}

main
