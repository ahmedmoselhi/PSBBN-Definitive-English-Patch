#!/bin/bash
echo -e "\e[8;30;100t"

TOOLKIT_PATH="$(pwd)"

clear
cd "${TOOLKIT_PATH}"

# Check if the helper files exists
if [[ ! -f "${TOOLKIT_PATH}/helper/PFS Shell.elf" || ! -f "${TOOLKIT_PATH}/helper/HDL Dump.elf" ]]; then
    echo "Required helper files not found. Please make sure you are in the 'PSBBN-Definitive-English-Patch'"
    echo "directory and try again."
    exit 1
fi

# Fetch updates from the remote
git fetch > /dev/null 2>&1

# Check the current status of the repository
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
  echo "The repository is up to date."
else
  echo "Downloading update..."
  git reset --hard && git pull --force > /dev/null 2>&1
  echo
  echo "The script has been updated to the latest version."
  read -p "Press any key to exit, then run the script again."
  exit 0
fi

echo "                                      _____      _               ";
echo "                                     /  ___|    | |              ";
echo "                                     \ \`--.  ___| |_ _   _ _ __  ";
echo "                                      \`--. \/ _ \ __| | | | '_ \ ";
echo "                                     /\__/ /  __/ |_| |_| | |_) |";
echo "                                     \____/ \___|\__|\__,_| .__/ ";
echo "                                                          | |    ";
echo "                                                          |_|    ";
echo
echo "   This script installs all dependencies required for the 'PSBBN Installer' and 'Game Installer'."
echo "   It must be run first."
echo
read -p "   Press any key to continue..."
echo

# Path to the sources.list file
SOURCES_LIST="/etc/apt/sources.list"

# Check if the file exists
if [[ -f "$SOURCES_LIST" ]]; then
    # Remove the "deb cdrom" line and store the result
if grep -q 'deb cdrom' "$SOURCES_LIST"; then
        sudo sed -i '/deb cdrom/d' "$SOURCES_LIST"
	echo "'deb cdrom' line has been removed from $SOURCES_LIST."
else
        echo "No 'deb cdrom' line found in $SOURCES_LIST."
fi
fi
# Check if user is on Debian-based system
if [ -x "$(command -v apt)" ]; then
    sudo apt update && sudo apt install -y axel imagemagick xxd python3 python3-venv python3-pip nodejs npm bc rsync curl zip
# Or if user is on Fedora-based system, do this instead
elif [ -x "$(command -v dnf)" ]; then
    sudo dnf install -y gcc axel ImageMagick xxd python3 python3-devel python3-pip nodejs npm bc rsync curl zip
# Or if user is on Arch-based system, do this instead
elif [ -x "$(command -v pacman)" ]; then
    sudo pacman -Sy --needed archlinux-keyring && sudo pacman -S --needed axel imagemagick xxd python pyenv python-pip nodejs npm bc rsync curl zip
fi
if [ $? -ne 0 ]; then
    echo
    echo "Error: Package installation failed."
    read -p "Press any key to exit..."
    exit 1
fi

# Check if mkfs.exfat exists, and install exfat-fuse if not
if ! command -v mkfs.exfat &> /dev/null; then
    echo
    echo "mkfs.exfat not found. Installing exfat driver..."
if [ -x "$(command -v apt)" ]; then
    sudo apt install -y exfat-fuse
elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y exfatprogs
elif [ -x "$(command -v pacman)" ]; then
	sudo pacman -S exfatprogs
fi
if [ $? -ne 0 ]; then
    	echo
    	echo "Error: Failed to install exfat driver."
    	read -p "Press any key to exit..."
    	exit 1
fi
fi

# Setup Python virtual environment and install Python dependencies
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo
    echo "Error: Failed to create Python virtual environment."
    read -p "Press any key to exit..."
    exit 1
fi

source venv/bin/activate
pip install lz4 natsort
if [ $? -ne 0 ]; then
    echo
    echo "Error: Failed to install Python dependencies."
    read -p "Press any key to exit..."
    deactivate
    exit 1
fi
deactivate

echo
echo "Setup completed successfully!"
read -p "Press any key to exit..."
