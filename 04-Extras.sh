#!/bin/bash
# Set terminal size: 100 columns and 40 rows
echo -e "\e[8;40;100t"

# Set paths
TOOLKIT_PATH="$(pwd)"
HELPER_DIR="${TOOLKIT_PATH}/helper"
ASSETS_DIR="${TOOLKIT_PATH}/assets"
LOG_FILE="${TOOLKIT_PATH}/extras.log"

error_msg() {
    type=$1
    error_1="$2"
    error_2="$3"
    error_3="$4"
    error_4="$5"

    echo
    echo "$type: $error_1" | tee -a "${LOG_FILE}"
    [ -n "$error_2" ] && echo "$error_2" | tee -a "${LOG_FILE}"
    [ -n "$error_3" ] && echo "$error_3" | tee -a "${LOG_FILE}"
    [ -n "$error_4" ] && echo "$error_4" | tee -a "${LOG_FILE}"
    echo
    if [ "$type" = "Error" ]; then
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1;
    else
        read -n 1 -s -r -p "Press any key to continue..."
        echo
    fi
}

cd "${TOOLKIT_PATH}"

echo "########################################################################################################" | tee -a "${LOG_FILE}" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo rm -f "${LOG_FILE}"
    echo "########################################################################################################" | tee -a "${LOG_FILE}" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo
        echo "Error: Cannot to create log file."
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
fi

# Check if the current directory is a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "This is not a Git repository. Skipping update check." | tee -a "${LOG_FILE}"
else
  # Fetch updates from the remote
  git fetch >> "${LOG_FILE}" 2>&1

  # Check the current status of the repository
  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u})
  BASE=$(git merge-base @ @{u})

  if [ "$LOCAL" = "$REMOTE" ]; then
    echo "The repository is up to date." | tee -a "${LOG_FILE}"
  else
    echo "Downloading updates..."
    # Get a list of files that have changed remotely
    UPDATED_FILES=$(git diff --name-only "$LOCAL" "$REMOTE")

    if [ -n "$UPDATED_FILES" ]; then
      echo "Files updated in the remote repository:" | tee -a "${LOG_FILE}"
      echo "$UPDATED_FILES" | tee -a "${LOG_FILE}"

      # Reset only the files that were updated remotely (discard local changes to them)
      echo "$UPDATED_FILES" | xargs git checkout -- >> "${LOG_FILE}" 2>&1

      # Pull the latest changes
      if ! git pull --ff-only >> "${LOG_FILE}" 2>&1; then
        error_msg "Error" "Update failed. Delete the PSBBN-Definitive-English-Patch directory and run the command:" " " "git clone https://github.com/CosmicScale/PSBBN-Definitive-English-Patch.git" " " "Then try running the script again."
      fi
      echo
      echo "The repository has been successfully updated." | tee -a "${LOG_FILE}"
      read -n 1 -s -r -p "Press any key to exit, then run the script again."
      echo
      exit 0
    fi
  fi
fi

date >> "${LOG_FILE}"
echo >> "${LOG_FILE}"
cat /etc/*-release >> "${LOG_FILE}" 2>&1

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Error: This script requires an x86-64 CPU architecture. Detected: $(uname -m)" | tee -a "${LOG_FILE}"
  read -n 1 -s -r -p "Press any key to exit..."
  echo
  exit 1
fi

# Function to detect PS2 HDD

function detect_drive() {
    DEVICE=$(sudo blkid -t TYPE=exfat | grep OPL | awk -F: '{print $1}' | sed 's/[0-9]*$//')

    if [[ -z "$DEVICE" ]]; then
        echo | tee -a "${LOG_FILE}"
        echo "Error: Unable to detect PS2 drive." | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return 1
    fi

    echo "OPL partition found on $DEVICE" >> "${LOG_FILE}"

    # Find all mounted volumes associated with the device
    mounted_volumes=$(lsblk -ln -o MOUNTPOINT "$DEVICE" | grep -v "^$")

    # Iterate through each mounted volume and unmount it
    echo "Unmounting volumes associated with $DEVICE..." >> "${LOG_FILE}"
    for mount_point in $mounted_volumes; do
        echo "Unmounting $mount_point..." >> "${LOG_FILE}"
        if sudo umount "$mount_point"; then
            echo "Successfully unmounted $mount_point." >> "${LOG_FILE}"
        else
            echo "Failed to unmount $mount_point. Please unmount manually." | tee -a "${LOG_FILE}"
            read -n 1 -s -r -p "Press any key to return to the main menu..."
            return 1
        fi
    done

    if ! sudo "${HELPER_DIR}/HDL Dump.elf" toc $DEVICE >> "${LOG_FILE}" 2>&1; then
        echo
        echo "Error: APA partition is broken on ${DEVICE}." | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return 1
    else
        echo
        echo "PS2 HDD detected as $DEVICE" | tee -a "${LOG_FILE}"
    fi
}

check_device_size() {
    # Get the size of the device in bytes
    SIZE_CHECK=$(lsblk -o NAME,SIZE -b | grep -w "$(basename "$DEVICE")" | awk '{print $2}')
    
    # Check if we successfully got a size
    if [[ -z "$SIZE_CHECK" ]]; then
        echo "Error: Could not determine device size."
        return 1
    fi

    # Convert size to GB (1 GB = 1,000,000,000 bytes)
    size_gb=$(echo "$SIZE_CHECK / 1000000000" | bc)

    if (( size_gb > 960 )); then
        echo
        echo "Warning: Device is $size_gb GB. HDD-OSD may experience issues with drives larger than 960 GB." | tee -a "${LOG_FILE}"
        echo
        read -rp "Continue anyway? (y/n): " answer
        case "$answer" in
            [Yy]*) echo "Continuing...";;
            *) echo "Aborting."; return 1;;
        esac
    fi
}

function hdd_osd_files_present() {
    local files=(
        FNTOSD
        HDD-OSD.elf
        hdd-osd.ico
        hosdsys.elf
        ICOIMAGE
        JISUCS
        PSBBN.ELF
        psbbn.ico
        SKBIMAGE
        SNDIMAGE
        TEXIMAGE
    )

    for file in "${files[@]}"; do
        if [[ ! -f "${ASSETS_DIR}/HDD-OSD/$file" ]]; then
            return 1  # false
        fi
    done

    return 0  # true
}

function download_files() {
# Check for HDD-OSD files
    if hdd_osd_files_present; then
        echo | tee -a "${LOG_FILE}"
        echo "All required files are present. Skipping download" | tee -a "${LOG_FILE}"
    else
        echo | tee -a "${LOG_FILE}"
        echo "Required files are missing in ${ASSETS_DIR}/HDD-OSD." | tee -a "${LOG_FILE}"
        # Check if HDD-OSD.zip exists
        if [[ -f "${ASSETS_DIR}/HDD-OSD.zip" && ! -f "${ASSETS_DIR}/HDD-OSD.zip.st" ]]; then
            echo | tee -a "${LOG_FILE}"
            echo "HDD-OSD.zip found in ${ASSETS_DIR}. Extracting..." | tee -a "${LOG_FILE}"
            unzip -o "${ASSETS_DIR}/HDD-OSD.zip" -d "${ASSETS_DIR}" >> "${LOG_FILE}" 2>&1
        else
            echo | tee -a "${LOG_FILE}"
            echo "Downloading required files..." | tee -a "${LOG_FILE}"
            axel -a https://archive.org/download/PSBBN-HDD-OSD/HDD-OSD.zip -o "${ASSETS_DIR}"
            unzip -o "${ASSETS_DIR}/HDD-OSD.zip" -d "${ASSETS_DIR}" >> "${LOG_FILE}" 2>&1
        fi
        # Check if HDD-OSD files exist after extraction
        if hdd_osd_files_present; then
            echo | tee -a "${LOG_FILE}"
            echo "Files successfully extracted." | tee -a "${LOG_FILE}"
        else
            echo | tee -a "${LOG_FILE}"
            echo "Error: One or more files are missing after extraction." | tee -a "${LOG_FILE}"
            read -n 1 -s -r -p "Press any key to return to the main menu..."
            return 1
        fi
    fi
}

# Function for Option 1 - Install HDD-OSD
function option_one() {

    clear

    if ! detect_drive; then
        return
    fi

    # Now check size
    if ! check_device_size; then
        return
    fi

    download_files

    # Copy HDD-OSD files to __system
    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mount __system\n"
    COMMANDS+="lcd '${ASSETS_DIR}/HDD-OSD'\n"
    COMMANDS+="mkdir osd110u\n"
    COMMANDS+="cd osd110u\n"
    COMMANDS+="put FNTOSD\n"
    COMMANDS+="put HDD-OSD.elf\n"
    COMMANDS+="put ICOIMAGE\n"
    COMMANDS+="put JISUCS\n"
    COMMANDS+="put SKBIMAGE\n"
    COMMANDS+="put SNDIMAGE\n"
    COMMANDS+="put TEXIMAGE\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    # Pipe all commands to PFS Shell for mounting, copying, and unmounting
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1

    cp "${ASSETS_DIR}/HDD-OSD/"{HDD-OSD.elf,PSBBN.ELF} "${TOOLKIT_PATH}/games/APPS" >> "${LOG_FILE}" 2>&1
    cp "${ASSETS_DIR}/HDD-OSD/"{hdd-osd.ico,psbbn.ico} "${TOOLKIT_PATH}/icons/ico" >> "${LOG_FILE}" 2>&1

    echo | tee -a "${LOG_FILE}"
    echo "HDD-OSD installed sucessfully." | tee -a "${LOG_FILE}"
    echo
    echo "Please run '03-Game-Installer.sh' to add HDD-OSD to the PSBBN Game Channel and update the icons"
    echo "for your game collection."
    echo
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function for Option 2 - Install PlayStation 2 Basic Boot Loader (PS2BBL)
function option_two() {
    clear
    
    download_files

    if ! detect_drive; then
        return
    fi

    # Copy PS2BBL files to __system and __sysconf
    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mount __system\n"
    COMMANDS+="lcd '${ASSETS_DIR}/HDD-OSD'\n"
    COMMANDS+="cd p2lboot\n"
    COMMANDS+="rename osdboot.elf osdboot.elf.bkp\n"
    COMMANDS+="put PSBBN.ELF\n"
    COMMANDS+="lcd '${ASSETS_DIR}/PS2BBL'\n"
    COMMANDS+="put osdboot.elf\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="mount __sysconf\n"
    COMMANDS+="mkdir PS2BBL\n"
    COMMANDS+="cd PS2BBL\n"
    COMMANDS+="put CONFIG.INI\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    # Pipe all commands to PFS Shell for mounting, copying, and unmounting
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1

    echo | tee -a "${LOG_FILE}"
    echo "PS2BBL installed sucessfully."
    echo
    read -n 1 -s -r -p "Press any key to return to the main menu..."

}

# Function for Option 3 - Uninstall PlayStation 2 Basic Boot Loader (PS2BBL)
function option_three() {
    clear

    if ! detect_drive; then
        return
    fi

    # Build the commands for PFS Shell
    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mount __system\n"
    COMMANDS+="cd p2lboot\n"
    COMMANDS+="ls\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    # Get the PS1 file list directly from PFS Shell output, filtered and sorted 
    bkp_check=$(echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" 2>/dev/null | grep "osdboot.elf.bkp")

    if [ -z "$bkp_check" ]; then
        echo | tee -a "${LOG_FILE}"
        echo "Error: osdboot.elf.bkp was not found. Uninstall failed." | tee -a "${LOG_FILE}"
        echo
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return
    fi


    # Copy PS2BBL files to __system and __sysconf
    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mount __system\n"
    COMMANDS+="cd p2lboot\n"
    COMMANDS+="rm osdboot.elf\n"
    COMMANDS+="rename osdboot.elf.bkp osdboot.elf\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="mount __sysconf\n"
    COMMANDS+="cd PS2BBL\n"
    COMMANDS+="rm CONFIG.INI\n"
    COMMANDS+="cd /\n"
    COMMANDS+="rmdir PS2BBL\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    # Pipe all commands to PFS Shell for mounting, copying, and unmounting
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1

    echo | tee -a "${LOG_FILE}"
    echo "PS2BBL sucessfully uninstalled."
    echo
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}


# Function to display the menu
function display_menu() {
    clear

    echo "                                     _____     _                 "
    echo "                                    |  ___|   | |                "
    echo "                                    | |____  _| |_ _ __ __ _ ___"
    echo "                                    |  __\\ \\/ / __| '__/ _\` / __|"
    echo "                                    | |___>  <| |_| | | (_| \\__ \\"
    echo "                                    \\____/_/\\_\\\\__|_|  \\__,_|___/"                      
    echo ""
    echo "                                        Written by CosmicScale"
    echo ""
    echo ""
    echo "     1) Install HDD-OSD/Browser 2.0"
    echo "     2) Install PlayStation 2 Basic Boot Loader (PS2BBL)"
    echo "     3) Uninstall PlayStation 2 Basic Boot Loader (PS2BBL)"
    echo "     q) Quit"
    echo ""
    echo ""
}

# Main loop

while true; do
    display_menu
    read -p "     Select an option: " choice

    case $choice in
        1)
            option_one
            ;;
        2)
            option_two
            ;;
        3)
            option_three
            ;;
        q|Q)
            break
            ;;
        *)
            echo
            echo "     Invalid option, please try again."
            sleep 2
            ;;
    esac
done
