#!/bin/bash
# Set terminal size: 100 columns and 40 rows
echo -e "\e[8;45;100t"

# Set paths
TOOLKIT_PATH="$(pwd)"
ASSETS_DIR="${TOOLKIT_PATH}/assets"
INSTALL_LOG="${TOOLKIT_PATH}/PSBBN-installer.log"

clear

cd "${TOOLKIT_PATH}"

# Check if the helper files exists
if [[ ! -f "${TOOLKIT_PATH}/helper/PFS Shell.elf" || ! -f "${TOOLKIT_PATH}/helper/HDL Dump.elf" ]]; then
    echo "Required helper files not found. Please make sure you are in the 'PSBBN-Definitive-English-Patch'"
    echo "directory and try again."
    exit 1
fi

echo "########################################################################################################">> "${INSTALL_LOG}";
date >> "${INSTALL_LOG}"
echo >> "${INSTALL_LOG}"
cat /etc/*-release >> "${INSTALL_LOG}" 2>&1
echo >> "${INSTALL_LOG}"
echo "Path set to: $TOOLKIT_PATH" >> "${INSTALL_LOG}"
echo "Helper files found." >> "${INSTALL_LOG}"

# Check if the current directory is a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "This is not a Git repository. Skipping update check." | tee -a "${INSTALL_LOG}"
else
  # Fetch updates from the remote
  git fetch >> "${INSTALL_LOG}" 2>&1

  # Check the current status of the repository
  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u})
  BASE=$(git merge-base @ @{u})

  if [ "$LOCAL" = "$REMOTE" ]; then
    echo "The repository is up to date." | tee -a "${INSTALL_LOG}"
  else
    echo "Downloading updates..."
    # Get a list of files that have changed remotely
    UPDATED_FILES=$(git diff --name-only "$LOCAL" "$REMOTE")

    if [ -n "$UPDATED_FILES" ]; then
      echo "Files updated in the remote repository:" | tee -a "${INSTALL_LOG}"
      echo "$UPDATED_FILES" | tee -a "${INSTALL_LOG}"

      # Reset only the files that were updated remotely (discard local changes to them)
      echo "$UPDATED_FILES" | xargs git checkout -- >> "${INSTALL_LOG}" 2>&1

      # Pull the latest changes
      git pull --ff-only >> "${INSTALL_LOG}" 2>&1

      echo "The script has been updated to the latest version." | tee -a "${INSTALL_LOG}"
      read -n 1 -s -r -p "Press any key to exit, then run the script again."
      echo
      exit 0
    else
      echo "The repository is up to date." | tee -a "${INSTALL_LOG}"
    fi
  fi
fi

# Choose the PS2 storage device
while true; do
    echo "              ______  _________________ _   _   _____          _        _ _           ";
    echo "              | ___ \/  ___| ___ \ ___ \ \ | | |_   _|        | |      | | |          ";
    echo "              | |_/ /\ \`--.| |_/ / |_/ /  \| |   | | _ __  ___| |_ __ _| | | ___ _ __ ";
    echo "              |  __/  \`--. \ ___ \ ___ \ . \` |   | || '_ \/ __| __/ _\` | | |/ _ \ '__|";
    echo "              | |    /\__/ / |_/ / |_/ / |\  |  _| || | | \__ \ || (_| | | |  __/ |   ";
    echo "              \_|    \____/\____/\____/\_| \_/  \___/_| |_|___/\__\__,_|_|_|\___|_|   ";
    echo "                                                                                    ";
    echo "                                       Written by CosmicScale"
    echo
    echo | tee -a "${INSTALL_LOG}"
    lsblk -p -o MODEL,NAME,SIZE,LABEL,MOUNTPOINT | tee -a "${INSTALL_LOG}"
    echo | tee -a "${INSTALL_LOG}"
        
    read -p "Choose your PS2 HDD from the list above (e.g., /dev/sdx): " DEVICE
    
    # Validate input
    if [[ $DEVICE =~ ^/dev/sd[a-z]$ ]]; then
        # Check the size of the chosen device
        SIZE_CHECK=$(lsblk -o NAME,SIZE -b | grep -w $(basename $DEVICE) | awk '{print $2}')

        # Convert size to GB (1 GB = 1,000,000,000 bytes)
        size_gb=$(echo "$SIZE_CHECK / 1000000000" | bc)
        
        if (( size_gb < 200 )); then
            echo
            echo "Error: Device is $size_gb GB. Required minimum is 200 GB."
            read -n 1 -s -r -p "Press any key to exit."
            echo
            exit 1
        fi

        echo
        echo -e "Are you sure you want to write to ${DEVICE}?" | tee -a "${INSTALL_LOG}"
        read -p "This will erase all data on the drive. (yes/no): " CONFIRM
        if [[ $CONFIRM == "yes" ]]; then
            break
        else
            echo "Aborted." | tee -a "${INSTALL_LOG}"
            read -n 1 -s -r -p "Press any key to exit..."
            echo
            exit 1
        fi
    else
        echo
        echo "Error: Invalid input. Please enter a valid device name (e.g., /dev/sdx)."
        read -n 1 -s -r -p "Press any key to try again..."
        clear
        echo
        continue
    fi
done

# Find all mounted volumes associated with the device
mounted_volumes=$(lsblk -ln -o MOUNTPOINT "$DEVICE" | grep -v "^$")

# Iterate through each mounted volume and unmount it
echo | tee -a "${INSTALL_LOG}"
echo "Unmounting volumes associated with $DEVICE..."
for mount_point in $mounted_volumes; do
    echo "Unmounting $mount_point..." | tee -a "${INSTALL_LOG}"
    if sudo umount "$mount_point"; then
        echo "Successfully unmounted $mount_point." | tee -a "${INSTALL_LOG}"
    else
        echo "Failed to unmount $mount_point. Please unmount manually." | tee -a "${INSTALL_LOG}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
done

echo "All volumes unmounted for $DEVICE."

# URL of the webpage
URL="https://archive.org/download/psbbn-definitive-english-patch-v2"
echo | tee -a "${INSTALL_LOG}"
echo "Checking for latest version of the PSBBN Definitive English patch..." | tee -a "${INSTALL_LOG}"

# Download the HTML of the page
HTML_FILE=$(mktemp)
wget -O "$HTML_FILE" "$URL" >> "${INSTALL_LOG}" 2>&1

# Extract .gz filenames from the HTML
COMBINED_LIST=$(grep -oP 'psbbn-definitive-image-v[0-9]+\.[0-9]+\.gz' "$HTML_FILE")

# Extract version numbers and sort them
VERSION_LIST=$(echo "$COMBINED_LIST" | \
    grep -oP 'v[0-9]+\.[0-9]+' | \
    sed 's/v//' | \
    sort -V)

# Determine the latest version from the sorted list
LATEST_VERSION=$(echo "$VERSION_LIST" | tail -n 1)

if [ -z "$LATEST_VERSION" ]; then
    echo "Could not find the latest version." | tee -a "${INSTALL_LOG}"
    # If $LATEST_VERSION is empty, check for psbbn-definitive-image*.gz files
    IMAGE_FILE=$(ls "${ASSETS_DIR}"/psbbn-definitive-image*.gz 2>/dev/null)
    if [ -n "$IMAGE_FILE" ]; then
        # If image file exists, set LATEST_FILE to the image file name
        LATEST_FILE=$(basename "$IMAGE_FILE")
        echo "Found local file: ${LATEST_FILE}" | tee -a "${INSTALL_LOG}"
    else
        rm "$HTML_FILE"
        echo "Failed to download PSBBN image file. Aborting." | tee -a "${INSTALL_LOG}"
        read -p "Press any key to exit..."
        exit 1
    fi
else
    LATEST_FILE="psbbn-definitive-image-v${LATEST_VERSION}.gz"
    echo "Latest version of PSBBN Definitive English patch is v${LATEST_VERSION}" | tee -a "${INSTALL_LOG}"
fi

# Check for and delete older files
for file in "${ASSETS_DIR}"/psbbn-definitive-image*.gz; do
    if [[ -f "$file" && "$(basename "$file")" != "$LATEST_FILE" ]]; then
        echo "Deleting old file: $file" | tee -a "${INSTALL_LOG}"
        rm "$file"
    fi
done

# Check if the latest file exists in ${ASSETS_DIR}
if [[ -f "${ASSETS_DIR}/${LATEST_FILE}" && ! -f "${ASSETS_DIR}/${LATEST_FILE}.st" ]]; then
    echo "File ${LATEST_FILE} exists in ${ASSETS_DIR}." | tee -a "${INSTALL_LOG}"
    echo "Skipping download" | tee -a "${INSTALL_LOG}"
else
    # Construct the full URL for the .gz file and download it
    ZIP_URL="$URL/$LATEST_FILE"
    echo "Downloading ${LATEST_FILE}..." | tee -a "${INSTALL_LOG}"
    axel -n 8 -a "$ZIP_URL" -o "${ASSETS_DIR}"

    # Check if the file was downloaded successfully
    if [[ -f "${ASSETS_DIR}/${LATEST_FILE}" && ! -f "${ASSETS_DIR}/${LATEST_FILE}.st" ]]; then
        echo "Download completed: ${LATEST_FILE}" | tee -a "${INSTALL_LOG}"
    else
        echo "Download failed for ${LATEST_FILE}. Please check your internet connection and try again." | tee -a "${INSTALL_LOG}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
fi

# Clean up
rm "$HTML_FILE"

echo | tee -a "${INSTALL_LOG}"
echo "Checking for POPS binaries..."

# Check POPS files exist
if [[ -f "${ASSETS_DIR}/POPS-binaries-main/POPS.ELF" && -f "${ASSETS_DIR}/POPS-binaries-main/IOPRP252.IMG" ]]; then
    echo "Both POPS.ELF and IOPRP252.IMG exist in ${ASSETS_DIR}." | tee -a "${INSTALL_LOG}"
    echo "Skipping download" | tee -a "${INSTALL_LOG}"
else
    echo "One or both files are missing in ${ASSETS_DIR}." | tee -a "${INSTALL_LOG}"
    # Check if POPS-binaries-main.zip exists
    if [[ -f "${ASSETS_DIR}/POPS-binaries-main.zip" && ! -f "${ASSETS_DIR}/POPS-binaries-main.zip.st" ]]; then
        echo | tee -a "${INSTALL_LOG}"
        echo "POPS-binaries-main.zip found in ${ASSETS_DIR}. Extracting..." | tee -a "${INSTALL_LOG}"
        unzip -o "${ASSETS_DIR}/POPS-binaries-main.zip" -d "${ASSETS_DIR}" >> "${INSTALL_LOG}" 2>&1
    else
        echo | tee -a "${INSTALL_LOG}"
        echo "Downloading POPS binaries..." | tee -a "${INSTALL_LOG}"
        axel -a https://archive.org/download/pops-binaries-PS2/POPS-binaries-main.zip -o "${ASSETS_DIR}"
        unzip -o "${ASSETS_DIR}/POPS-binaries-main.zip" -d "${ASSETS_DIR}" >> "${INSTALL_LOG}" 2>&1
    fi
    # Check if both POPS.ELF and IOPRP252.IMG exist after extraction
    if [[ -f "${ASSETS_DIR}/POPS-binaries-main/POPS.ELF" && -f "${ASSETS_DIR}/POPS-binaries-main/IOPRP252.IMG" ]]; then
        echo | tee -a "${INSTALL_LOG}"
        echo "POPS binaries successfully extracted." | tee -a "${INSTALL_LOG}"
    else
        echo | tee -a "${INSTALL_LOG}"
        echo "Error: One or both files (POPS.ELF, IOPRP252.IMG) are missing after extraction." | tee -a "${INSTALL_LOG}"
        read -n 1 -s -r -p "You can install POPS manually later. Press any key to continue..." | tee -a "${INSTALL_LOG}"
        echo
    fi
fi

PSBBN_IMAGE="${ASSETS_DIR}/${LATEST_FILE}"

# Write the PSBBN image
echo | tee -a "${INSTALL_LOG}"
echo "Writing the PSBBN image to ${DEVICE}..." | tee -a "${INSTALL_LOG}"
if gunzip -c ${PSBBN_IMAGE} | sudo dd of=${DEVICE} bs=4M status=progress 2>&1 | tee -a "${INSTALL_LOG}" ; then
    sync
    echo
    echo "Verifying installation..."
    if sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__common'; then
        echo "Verification successful. PSBBN image installed successfully." | tee -a "${INSTALL_LOG}"
        read -n 1 -s -r -p "Press any key to continue.."
        echo
    else
        echo "Error: Verification failed on ${DEVICE}." | tee -a "${INSTALL_LOG}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
else
    echo "Error: Failed to write the image to ${DEVICE}." | tee -a "${INSTALL_LOG}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Function to find available space
function function_space() {

output=$(sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc ${DEVICE} 2>&1)

# Check for the word "aborting" in the output
if echo "$output" | grep -q "aborting"; then
    echo "${DEVICE}: APA partition is broken; aborting." | tee -a "${INSTALL_LOG}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Extract the "used" value, remove "MB" and any commas
used=$(echo "$output" | awk '/used:/ {print $6}' | sed 's/,//; s/MB//')
capacity=124416

# Calculate available space (capacity - used)
available=$((capacity - used))
}

# Call the function retreive avaliable space
function_space

# Prompt user for partition size for music, validate input, and keep asking until valid input is provided
while true; do
  clear
  echo | tee -a "${INSTALL_LOG}"
  echo "Partitioning the first 128 GB of the drive:"
  echo
  echo "What size would you like the \"Music\" partition to be?" | tee -a "${INSTALL_LOG}"
  echo "Minimum 10 GB, Maximum 40 GB" | tee -a "${INSTALL_LOG}"
  read -p "Enter partition size (in GB): " gb_size

  if [[ ! "$gb_size" =~ ^[0-9]+$ ]]; then
    echo
    echo "Invalid input. Please enter a valid number." | tee -a "${INSTALL_LOG}"
    sleep 3
    continue
  fi

  if (( gb_size >= 10 && gb_size <= 40 )); then
    music_partition=$((gb_size * 1024 - 2048))

    echo | tee -a "${INSTALL_LOG}"
    echo "You have selected $gb_size GB for the \"Music\" partition." | tee -a "${INSTALL_LOG}"
    read -p "Do you wish to proceed? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      while true; do
        GB=$(((available - 14976 - music_partition ) / 1024))
        echo | tee -a "${INSTALL_LOG}"
        echo "What size would you like the \"POPS\" partition to be?" | tee -a "${INSTALL_LOG}"
        echo "The \"POPS\" partition is where PS1 games are stored." | tee -a "${INSTALL_LOG}"
        echo "Minimum 10 GB, Maximum $GB GB" | tee -a "${INSTALL_LOG}" | tee -a "${INSTALL_LOG}"
        read -p "Enter partition size (in GB): " gb_size

        if [[ ! "$gb_size" =~ ^[0-9]+$ ]]; then
          echo
          echo "Invalid input. Please enter a valid number." | tee -a "${INSTALL_LOG}"
          continue
        fi

        if (( gb_size >= 10 && gb_size <= GB )); then
          pops_partition=$((gb_size * 1024))
          game_partitions=$(((available - 2048 - music_partition - pops_partition) / 128))

          echo | tee -a "${INSTALL_LOG}"
          echo "You have selected $gb_size GB for the \"POPS\" partition." | tee -a "${INSTALL_LOG}"
          echo "This will allow for $game_partitions games in the PSBBN Game Channel." | tee -a "${INSTALL_LOG}"
          echo
          echo "If you require more games, reduce the size of your Music/POPS partitions." | tee -a "${INSTALL_LOG}"
          read -p "Do you wish to proceed? (y/n): " confirm
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            break 2  # Exit both loops
          else
            break  # Restart partitioning from the beginning
          fi
        else
          echo
          echo "Invalid size. Please enter a value between 10 and $GB GB." | tee -a "${INSTALL_LOG}"
        fi
      done
    fi
  else
    echo
    echo "Invalid size. Please enter a value between 10 and 40 GB." | tee -a "${INSTALL_LOG}"
    sleep 3
  fi
done

COMMANDS="device ${DEVICE}\n"
COMMANDS+="mkpart __linux.8 ${music_partition}M REISER\n"
COMMANDS+="mkpart __.POPS ${pops_partition}M PFS\n"
COMMANDS+="mkpart +OPL 128M PFS\nexit"
echo -e "$COMMANDS" | sudo "${TOOLKIT_PATH}/helper/PFS Shell.elf" >> "${INSTALL_LOG}" 2>&1

echo | tee -a "${INSTALL_LOG}"
echo "Installing POPS and OPL..." | tee -a "${INSTALL_LOG}"

cd "${TOOLKIT_PATH}/assets/"

# Copy POPS files and OPL to relevent partitions
COMMANDS="device ${DEVICE}\n"
COMMANDS+="mount +OPL\n"
COMMANDS+="put OPNPS2LD.ELF\n"
COMMANDS+="umount\n"
COMMANDS+="mount __common\n"
COMMANDS+="mkdir POPS\n"
COMMANDS+="cd POPS\n"
COMMANDS+="put IGR_BG.TM2\n"
COMMANDS+="put IGR_NO.TM2\n"
COMMANDS+="put IGR_YES.TM2\n"
COMMANDS+="lcd POPS-binaries-main\n"
COMMANDS+="put POPS.ELF\n"
COMMANDS+="put IOPRP252.IMG\n"
COMMANDS+="cd ..\n"
COMMANDS+="umount\n"
COMMANDS+="exit"

# Pipe all commands to PFS Shell for mounting, copying, and unmounting
echo -e "$COMMANDS" | sudo "${TOOLKIT_PATH}/helper/PFS Shell.elf" >> "${INSTALL_LOG}" 2>&1

cd "${TOOLKIT_PATH}"


#//////////////////////////////////////////////// APA-Jail code by Berion ////////////////////////////////////////////////

function function_apajail_magic_number() {
	echo ${MAGIC_NUMBER} | xxd -r -p > /tmp/apajail_magic_number.bin
	sudo dd if=/tmp/apajail_magic_number.bin of=${DEVICE} bs=8 count=1 seek=28 conv=notrunc >> "${INSTALL_LOG}" 2>&1
	}

function function_apa_checksum_fix() {
	sudo dd if=${DEVICE} of=/tmp/apa_header_full.bin bs=512 count=2 >> "${INSTALL_LOG}" 2>&1
	"${TOOLKIT_PATH}/helper/PS2 APA Header Checksum Fixer.elf" /tmp/apa_header_full.bin | sed -n 8p | awk '{print $6}' | xxd -r -p > /tmp/apa_header_checksum.bin
	sudo dd if=/tmp/apa_header_checksum.bin of=${DEVICE} conv=notrunc >> "${INSTALL_LOG}" 2>&1
	}

function function_clear_temp() {
	sudo rm /tmp/apa_header_address.bin		&> /dev/null
	sudo rm /tmp/apa_header_boot.bin			&> /dev/null
	sudo rm /tmp/apa_header_checksum.bin	&> /dev/null
	sudo rm /tmp/apa_header_full.bin			&> /dev/null
	sudo rm /tmp/apa_journal.bin				&> /dev/null
	sudo rm /tmp/apa_header_probe.bin		&> /dev/null
	sudo rm /tmp/apa_header_size.bin			&> /dev/null
	sudo rm /tmp/apajail_magic_number.bin	&> /dev/null
	sudo rm /tmp/apa_index.xz					&> /dev/null
	sudo rm /tmp/gpt_2nd.xz						&> /dev/null
	}

echo | tee -a "${INSTALL_LOG}"
echo "Running APA-Jail by Berion..." | tee -a "${INSTALL_LOG}"

# Signature injection (type A2):
MAGIC_NUMBER="4150414A2D413200"
function_apajail_magic_number

# Setting up MBR:
{
echo -e ",128GiB,17\n,32MiB,17\n,,07" | sudo sfdisk ${DEVICE}
sudo partprobe ${DEVICE}
if [ "$(echo ${DEVICE} | grep -o /dev/loop)" = "/dev/loop" ]; then
	sudo mkfs.ext2 -L "RECOVERY" ${DEVICE}p2
	sudo mkfs.exfat -c 32K -L "OPL" ${DEVICE}p3
	else
		sleep 4
		sudo mkfs.ext2 -L "RECOVERY" ${DEVICE}2
		sudo mkfs.exfat -c 32K -L "OPL" ${DEVICE}3
fi
} >> "${INSTALL_LOG}" 2>&1

PARTITION_NUMBER=3

# Finalising recovery:
if [ ! -d "${TOOLKIT_PATH}/storage/hdd/recovery" ]; then
	mkdir -p "${TOOLKIT_PATH}/storage/hdd/recovery"
fi
if [ "$(echo ${DEVICE} | grep -o /dev/loop)" = "/dev/loop" ]; then
	sudo mount ${DEVICE}p2 "${TOOLKIT_PATH}/storage/hdd/recovery"
	else sudo mount ${DEVICE}2 "${TOOLKIT_PATH}/storage/hdd/recovery"
fi
sudo dd if=${DEVICE} bs=128M count=1 status=noxfer 2>> "${INSTALL_LOG}" | xz -z > /tmp/apa_index.xz 2>> "${INSTALL_LOG}"
sudo cp /tmp/apa_index.xz "${TOOLKIT_PATH}/storage/hdd/recovery"
LBA_MAX=$(sudo blockdev --getsize ${DEVICE})
LBA_GPT_BUP=$(echo $(($LBA_MAX-33)))
sudo dd if=${DEVICE} skip=${LBA_GPT_BUP} bs=512 count=33 status=noxfer 2>> "${INSTALL_LOG}" | xz -z > /tmp/gpt_2nd.xz 2>> "${INSTALL_LOG}"
sudo cp /tmp/gpt_2nd.xz "${TOOLKIT_PATH}/storage/hdd/recovery"
sync
sudo umount -l "${TOOLKIT_PATH}/storage/hdd/recovery"
rmdir "${TOOLKIT_PATH}/storage/hdd/recovery"

function_apa_checksum_fix

function_clear_temp

unset LBA_GPT_BUP
unset LBA_MAX
unset MAGIC_NUMBER
unset PARTITION_NUMBER

#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# Run the command and capture output
output=$(sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc ${DEVICE} 2>&1)

# Check for the word "aborting" in the output
if echo "$output" | grep -q "aborting"; then
    echo "Error: APA partition is broken on ${DEVICE}. Install failed." | tee -a "${INSTALL_LOG}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

if sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__.POPS' && \
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__linux.8' && \
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '+OPL'; then
   echo
   echo "POPS, Music and +OPL partitions were created successfully." | tee -a "${INSTALL_LOG}"
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" >> "${INSTALL_LOG}"
else
    echo
    echo "Error: Some partitions are missing on ${DEVICE}. See log for details." | tee -a "${INSTALL_LOG}"
    sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" >> "${INSTALL_LOG}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Check if 'OPL' is found in the 'lsblk' output and if it matches the device
if ! lsblk -p -o NAME,LABEL | grep -q "${DEVICE}3"; then
    echo "Error: APA-Jail failed on ${DEVICE}." | tee -a "${INSTALL_LOG}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo | tee -a "${INSTALL_LOG}"
echo "PSBBN successfully installed." | tee -a "${INSTALL_LOG}"
read -n 1 -s -r -p "Press any key to exit. "
echo
