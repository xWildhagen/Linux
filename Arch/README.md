# Arch

An automated, interactive, and modular toolkit for installing and configuring Arch Linux, managing dotfiles, and setting up a fully personalized environment.

## Features

- **Modular Architecture**: Scripts are logically grouped into discrete installation phases (Archinstall configuration, package management, home directory setup).
- **Interactive CLI**: A centralized menu-driven `main.sh` wrapper provides a guided experience for executing each setup stage.
- **Safety and Reliability**: Follows strict bash scripting standards, robust error handling, and visual feedback using custom color-coded output helpers.
- **Dotfiles Management**: Seamlessly integrates cloning and linking dotfiles into the home setup process.

## Prerequisites

Ensure you have the following prerequisites before proceeding with the installation:

- **Arch Linux Live USB**: Booted into the live environment (with internet access).
- **Internet Connection**: Either wired (automatically configured via DHCP) or wireless.
  ```bash
  iwctl
  station wlan0 connect "SSID"
  exit
  ```
- **Base Packages**: Ensure `git` and `archinstall` are available on the live media.

## Installation & Setup

1. **Load Keymap (Optional)**
   Configure your keyboard layout if it differs from the default US layout.

   ```bash
   loadkeys no
   ```

2. **Sync and Install Dependencies**
   Update the package database and install `git` and `archinstall` required for the setup.

   ```bash
   pacman -Sy git archinstall
   ```

3. **Clone the Repository**
   Pull this repository directly to the root of the live environment.

   ```bash
   git clone https://github.com/xwildhagen/arch
   ```

4. **Run the Project**
   Execute the central wrapper script to access the interactive installation menu.
   ```bash
   arch/main.sh
   ```

## Usage

From the `main.sh` interactive menu, you can execute the following phases:

1. **Start archinstall**: Generates and executes the base Arch Linux installation using predefined configurations.
2. **Start package installation**: Automates the installation of system packages, `yay` (AUR helper), and user-specific software groups.
3. **Start home setup**: Configures user settings, clones dotfiles, and finalizes the customized environment setup.

### Remote Access (SSH) Setup

If you wish to run the installation remotely via SSH:

1. **Set Root Password**
   Assign a temporary password to the root user on the live USB.

   ```bash
   passwd
   ```

2. **Connect to Wi-Fi (if not wired)**

   ```bash
   iwctl
   station wlan0 connect "SSID"
   exit
   ```

3. **Find the IP Address**

   ```bash
   ip a
   ```

4. **Connect via SSH from another machine**
   ```bash
   ssh root@<IP_ADDRESS>
   ```

### Updating the Repository

To quickly pull down updates to the scripts without re-cloning:

```bash
git -C arch reset --hard
git -C arch pull
```
