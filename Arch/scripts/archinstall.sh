#!/bin/bash

ARCHINSTALL_CONFIG="${HOME}/arch/archinstall/user_configuration.json"
ARCHINSTALL_CREDS="${HOME}/arch/archinstall/user_credentials.json"

run_archinstall() {
    echo_color BLUE "Checking ARCHINSTALL_CONFIG file..."
    if [ ! -f "${ARCHINSTALL_CONFIG}" ]; then
        echo_color RED "Error: Archinstall configuration file not found at ${ARCHINSTALL_CONFIG}"
        return 1
    fi

    echo_color BLUE "Checking ARCHINSTALL_CREDS file..."
    if [ ! -f "${ARCHINSTALL_CREDS}" ]; then
        echo_color RED "Error: Archinstall credentials file not found at ${ARCHINSTALL_CREDS}"
        return 1
    fi

    echo_color BLUE "Starting archinstall..."
    if archinstall --config $ARCHINSTALL_CONFIG --creds $ARCHINSTALL_CREDS; then
        clear
        return 0
    else
        return 1
    fi

    return 0
}

post_install() {
    echo_color BLUE "Performing post-installation setup..."
    echo_color BLUE "Cloning repository..."
    arch-chroot /mnt git clone https://github.com/xwildhagen/arch.git /home/wildhagen/arch || { echo_color RED "Error: Could not clone repository"; return 1; }

    echo_color BLUE "Setting permissions..."
    arch-chroot /mnt chown -R 1000:1000 "/home/wildhagen/" || { echo_color RED "Error: Could not set permissions"; return 1; }
    arch-chroot /mnt chmod -R +rx "/home/wildhagen/" || { echo_color RED "Error: Could not set permissions"; return 1; }
    
    echo_color GREEN "Post-installation setup complete."

    return 0
}

archinstall_main() {
    starting "ARCHINSTALL SETUP"

    if ! run_archinstall; then
        failed "ARCHINSTALL"
        return 1
    fi

    if ! post_install; then
        failed "POST-INSTALL"
    fi

    complete "ARCHINSTALL SETUP"

    reboot

    return 0
}