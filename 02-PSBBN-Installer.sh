#!/bin/bash
# Set terminal size: 100 columns and 40 rows
echo -e "\e[8;40;100t"

# Set paths
TOOLKIT_PATH="$(pwd)"
ASSETS_DIR="${TOOLKIT_PATH}/assets"
INSTALL_LOG="${TOOLKIT_PATH}/PSBBN-installer.log"

clear

# Check if the helper files exists
if [[ ! -f "${TOOLKIT_PATH}/helper/PFS Shell.elf" || ! -f "${TOOLKIT_PATH}/helper/HDL Dump.elf" ]]; then
    echo "Required helper files not found. Please make sure you are in the 'PSBBN-Definitive-English-Patch'"
    echo "directory and try again."
    exit 1
else
    echo "####################################################################">> "${INSTALL_LOG}";
    date >> "${INSTALL_LOG}"
    echo >> "${INSTALL_LOG}"
    echo "Path set to: $TOOLKIT_PATH" >> "${INSTALL_LOG}"
    echo "Helper files found." >> "${INSTALL_LOG}"
fi

# Choose the PS2 storage device
while true; do
    clear
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
        SIZE_CHECK=$(lsblk -o NAME,SIZE | grep -w $(basename $DEVICE) | tr -s ' ' | cut -d' ' -f2 | cut -d'.' -f1)
        
        if (( SIZE_CHECK < 200 )); then
            echo
            echo "Error: Device is $SIZE_CHECK GB. Required minimum is 200 GB."
            read -p "Press any key to exit."
            exit 1
        fi

        echo
        echo -e "Are you sure you want to write to ${DEVICE}?" | tee -a "${INSTALL_LOG}"
        read -p "This will erase all data on the drive. (yes/no): " CONFIRM
        if [[ $CONFIRM == "yes" ]]; then
            break
        else
            echo "Aborted." | tee -a "${INSTALL_LOG}"
            read -p "Press any key to exit..."
            exit 1
        fi
    else
        echo
        echo "Error: Invalid input. Please enter a valid device name (e.g., /dev/sdx)."
        read -p "Press any key to try again..."
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
        read -p "Press any key to exit..."
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

# Extract .gz links and dates into a combined list
COMBINED_LIST=$(grep -oP '(?<=<td><a href=")[^"]+\.gz' "$HTML_FILE" | \
                paste -d' ' <(grep -oP '(?<=<td>)[^<]+(?=</td>)' "$HTML_FILE" | \
                             grep -E '^\d{2}-\w{3}-\d{4}') -)

# Sort the combined list by date (most recent first), and get the latest file
LATEST=$(echo "$COMBINED_LIST" | sort -r | head -n 1 | cut -d' ' -f2)

if [ -z "$LATEST" ]; then
    echo "Cound not find latest version."
    # If $LATEST is empty, check for psbbn-definitive-image*.gz file
    IMAGE_FILE=$(ls "${ASSETS_DIR}"/psbbn-definitive-image*.gz 2>/dev/null)
    if [ -n "$IMAGE_FILE" ]; then
        # If image file exists, set LATEST to the image file name
        LATEST=$(basename "$IMAGE_FILE")
        echo "Found local file: ${LATEST}" | tee -a "${INSTALL_LOG}"
    else
        rm "$HTML_FILE"
        echo "Failed to download PSBBN image file. Aborting." | tee -a "${INSTALL_LOG}"
        read -p "Press any key to exit..."
        exit 1
    fi
else
    echo "Latest version of PSBBN Definitive English patch is $LATEST"
fi

# Check for and delete older 'psbbn-definitive-image*.gz' files
for file in "${ASSETS_DIR}"/psbbn-definitive-image*.gz; do
    if [[ -f "$file" && "$(basename "$file")" != "$LATEST" ]]; then
        echo "Deleting old file: $file" | tee -a "${INSTALL_LOG}"
        rm "$file"
    fi
done

# Check if the file exists in ${ASSETS_DIR}
if [[ -f "${ASSETS_DIR}/${LATEST}" && ! -f "${ASSETS_DIR}/${LATEST}.st" ]]; then
    echo "File ${LATEST} exists in ${ASSETS_DIR}." | tee -a "${INSTALL_LOG}"
    echo "Skipping download" | tee -a "${INSTALL_LOG}"
else
    # Construct the full URL for the .gz file and download it
    ZIP_URL="$URL/$LATEST"
    # Proceed with download
    echo "Downloading ${LATEST}..." | tee -a "${INSTALL_LOG}"
    axel -n 8 -a "$ZIP_URL" -o "${ASSETS_DIR}"

    # Check if the file was downloaded successfully
    if [[ -f "${ASSETS_DIR}/${LATEST}" && ! -f "${ASSETS_DIR}/${LATEST}.st" ]]; then
        echo "Download completed: ${LATEST}" | tee -a "${INSTALL_LOG}"
    else
        rm "$HTML_FILE"
        echo "Download failed for ${LATEST}. Please check your internet connection and try again." | tee -a "${INSTALL_LOG}"
        read -p "Press any key to exit..."
        exit 1
    fi

    # Clean up
    rm "$HTML_FILE"
fi

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
        read -p "You can install POPS manually later. Press any key to continue..." | tee -a "${INSTALL_LOG}"
    fi
fi

PSBBN_IMAGE="${ASSETS_DIR}/${LATEST}"

# Write the PSBBN image
echo | tee -a "${INSTALL_LOG}"
echo "Writing the PSBBN image to ${DEVICE}..." | tee -a "${INSTALL_LOG}"
if gunzip -c ${PSBBN_IMAGE} | sudo dd of=${DEVICE} bs=4M status=progress 2>&1 | tee -a "${INSTALL_LOG}" ; then
    sync
    echo
    echo "Verifying installation..."
    if sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__common'; then
        echo "Verification successful. PSBBN image installed successfully." | tee -a "${INSTALL_LOG}"
    else
        echo "Error: Verification failed on ${DEVICE}." | tee -a "${INSTALL_LOG}"
        read -p "Press any key to exit..."
        exit 1
    fi
else
    echo "Error: Failed to write the image to ${DEVICE}." | tee -a "${INSTALL_LOG}"
    read -p "Press any key to exit..."
    exit 1
fi

# Function to find available space
function function_space() {
    

output=$(sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc ${DEVICE} 2>&1)

# Check for the word "aborting" in the output
if echo "$output" | grep -q "aborting"; then
    echo "${DEVICE}: APA partition is broken; aborting." | tee -a "${INSTALL_LOG}"
    read -p "Press any key to exit..."
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

# Divide available space by 128 to calculate the maximum number of partitions
PP=$(((available - 18560) / 128))

# Loop until the user enters a valid number of partitions
while true; do
    echo | tee -a "${INSTALL_LOG}"
    echo "    #########################################################################################"
    echo "    #  'OPL Launcher' partitions are used to launch games from the 'Game Channel.'          #"
    echo "    #  Consider how many games you want to install, and plan for future expansion.          #"
    echo "    #  Additional 'OPL Launcher' partitions cannot be created after setup.                  #"
    echo "    #                                                                                       #"
    echo "    #  Note: The more partitions you create, the longer it will take to load the game list. #"
    echo "    #  Fewer 'OPL Launcher' partitions leave more space for the 'Music' partition           #"
    echo "    #  and the 'POPS' partition for PS1 games.                                              #"
    echo "    #                                                                                       #"
    echo "    #  A good starting point is 200 partitions, but feel free to experiment.                #"
    echo "    #########################################################################################"
    echo
    read -p "Enter the number of \"OPL Launcher\" partitions you would like (1-$PP): " PARTITION_COUNT

    # Check if input is a valid number within the specified range
    if [[ "$PARTITION_COUNT" =~ ^[0-9]+$ ]] && [ "$PARTITION_COUNT" -ge 1 ] && [ "$PARTITION_COUNT" -le $PP ]; then
        break  # Exit the loop if the input is valid
    else
        echo "Invalid input. Please enter a number between 1 and $PP." | tee -a "${INSTALL_LOG}"
    fi
done

GB=$(((available + 2048 - 10368 - (PARTITION_COUNT * 128)) / 1024))

# Prompt user for partition size for music, validate input, and keep asking until valid input is provided
while true; do
  echo | tee -a "${INSTALL_LOG}"
  echo "What size would you like the \"Music\" partition to be?" | tee -a "${INSTALL_LOG}"
  echo "Remaining space will be allocated to the __.POPS partition for PS1 games"
  echo "Minimum 10 GB, Available space: $GB GB" | tee -a "${INSTALL_LOG}"
  read -p "Enter partition size (in GB): " gb_size

  # Check if the input is a valid number
  if [[ ! "$gb_size" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a valid number." | tee -a "${INSTALL_LOG}"
    continue
  fi

  # Check if the value is within the valid range
  if (( gb_size >= 10 && gb_size <= GB )); then
    echo "Valid partition size: $gb_size GB" | tee -a "${INSTALL_LOG}"
    break  # Exit the loop if the input is valid
  else
    echo "Invalid size. Please enter a value between 10 and $GB GB." | tee -a "${INSTALL_LOG}"
  fi
done

music_partition=$((gb_size * 1024 - 2048))
pops_partition=$((available - (PARTITION_COUNT * 128) - music_partition -128))
GB=$((pops_partition / 1024))

echo | tee -a "${INSTALL_LOG}"
echo "$GB GB alocated for __.POPS partition." | tee -a "${INSTALL_LOG}"

COMMANDS="device ${DEVICE}\n"
COMMANDS+="mkpart __linux.8 ${music_partition}M REISER\n"
COMMANDS+="mkpart __.POPS ${pops_partition}M PFS\n"
COMMANDS+="mkpart +OPL 128M PFS\nexit"
echo -e "$COMMANDS" | sudo "${TOOLKIT_PATH}/helper/PFS Shell.elf" >> "${INSTALL_LOG}" 2>&1


# Call the function to retrieve available space
function_space

echo | tee -a "${INSTALL_LOG}"
echo "Creating $PARTITION_COUNT \"OPL Launcher\" partitions..." | tee -a "${INSTALL_LOG}"

# Set starting partition number
START_PARTITION_NUMBER=1

# Initialize a counter for the successfully created partitions
successful_count=0

# Loop to create the specified number of partitions
for ((i = 0; i < PARTITION_COUNT; i++)); do
    # Check if available space is at least 128 MB
    if [ "$available" -lt 128 ]; then
        echo | tee -a "${INSTALL_LOG}"
        echo "Insufficient space for another partition." | tee -a "${INSTALL_LOG}"
        break
    fi

    # Calculate the current partition number (starting at $START_PARTITION_NUMBER)
    PARTITION_NUMBER=$((START_PARTITION_NUMBER + i))

    # Generate the partition label dynamically (PP.001, PP.002, etc.)
    PARTITION_LABEL=$(printf "PP.%03d" "$PARTITION_NUMBER")

    # Build the command to create this partition
    COMMAND="device ${DEVICE}\nmkpart ${PARTITION_LABEL} 128M PFS\nexit"

    # Run the partition creation command in PFS Shell
    echo -e "$COMMAND" | sudo "${TOOLKIT_PATH}/helper/PFS Shell.elf" >> "${INSTALL_LOG}" 2>&1

    # Increment the count of successfully created partitions
    ((successful_count++))

    # Call function_space after exiting PFS Shell to update the available space
    function_space
done

# Display the total number of partitions created successfully
echo | tee -a "${INSTALL_LOG}"
echo "$successful_count \"OPL Launcher\" partitions created successfully." | tee -a "${INSTALL_LOG}"

echo | tee -a "${INSTALL_LOG}"
echo "Modifying partition headers..." | tee -a "${INSTALL_LOG}"

cd "${TOOLKIT_PATH}/assets/"

# After partitions are created, modify the header for each partition
for ((i = START_PARTITION_NUMBER; i < START_PARTITION_NUMBER + PARTITION_COUNT; i++)); do
    PARTITION_LABEL=$(printf "PP.%03d" "$i")
    sudo "${TOOLKIT_PATH}/helper/HDL Dump.elf" modify_header "${DEVICE}" "${PARTITION_LABEL}" >> "${INSTALL_LOG}" 2>&1
done

echo | tee -a "${INSTALL_LOG}"
echo "Making \"res\" folders..." | tee -a "${INSTALL_LOG}"

# make 'res' directory on all PP partitions
COMMANDS="device ${DEVICE}\n"
for ((i = START_PARTITION_NUMBER; i < START_PARTITION_NUMBER + PARTITION_COUNT; i++)); do
    PARTITION_LABEL=$(printf "PP.%03d" "$i")
    COMMANDS+="mount ${PARTITION_LABEL}\n"
    COMMANDS+="mkdir res\n"
    COMMANDS+="umount\n"
done
COMMANDS+="exit"

# Pipe all commands to PFS Shell for mounting, copying, and unmounting
echo -e "$COMMANDS" | sudo "${TOOLKIT_PATH}/helper/PFS Shell.elf" >> "${INSTALL_LOG}" 2>&1

echo | tee -a "${INSTALL_LOG}"
echo "Installing POPS and OPL..." | tee -a "${INSTALL_LOG}"

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

function function_disk_size_check() {
	LBA_MAX=$(sudo blockdev --getsize ${DEVICE})
	if [ ${LBA_MAX} -gt 4294967296 ]; then
		echo -e "ERROR: Disk size exceeding 2TiB. Formatting aborted." | tee -a "${INSTALL_LOG}"
		function_exit
	fi
	}


function function_apajail_magic_number() {
	echo ${MAGIC_NUMBER} | xxd -r -p > /tmp/apajail_magic_number.bin
	sudo dd if=/tmp/apajail_magic_number.bin of=${DEVICE} bs=8 count=1 seek=28 conv=notrunc >> "${INSTALL_LOG}" 2>&1
	}

function function_make_ps2_dirs() {
	if [ ! -d "/tmp/ps2_dirs" ]; then
		mkdir /tmp/ps2_dirs
	fi	
	if [ "$(echo ${DEVICE} | grep -o /dev/loop)" = "/dev/loop" ]; then
		sudo mount ${DEVICE}p${PARTITION_NUMBER} /tmp/ps2_dirs
		else sudo mount ${DEVICE}${PARTITION_NUMBER} /tmp/ps2_dirs
	fi
	cd /tmp/ps2_dirs
	sudo mkdir -p APPS/		# Open PS2 Loader: applications 
	sudo mkdir -p ART/		# Open PS2 Loader: disc covers (<GameID>_COV.png, <GameID>_ICO.png, <GameID>_SCR.png etc.)
	sudo mkdir -p CFG/		# Open PS2 Loader: per game configs (<GameID>.cfg)
	sudo mkdir -p CHT/		# Open PS2 Loader: cheats (<GameID>.cht)
	sudo mkdir -p CD/		# Open PS2 Loader: CD disc images (*.iso, *.zso)
	sudo mkdir -p DVD/		# Open PS2 Loader: DVD disc images (*.iso, *.zso)
	sudo mkdir -p LNG		# Open PS2 Loader: Language files
	sudo mkdir -p THM/		# Open PS2 Loader: theme dirs (thm_<ThemeName>/*)
	sudo mkdir -p VMC/		# Open PS2 Loader: non-ECC PS2 Memory Card images (generic or <GameID>_0.bin, <GameID>_1.bin)
	sync
	sudo umount -l /tmp/ps2_dirs
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

# Hashed out for testing. Larger drive support most likley possible when using a restored disc image from a smaller drive
# function_disk_size_check

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
function_make_ps2_dirs

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
    read -p "Press any key to exit..."
    exit 1
fi

if sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__.POPS' && \
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '__linux.8' && \
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q "PP.${PARTITION_COUNT}" && \
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" | grep -q '+OPL'; then
   echo "All partitions were created successfully." | tee -a "${INSTALL_LOG}"
   sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" >> "${INSTALL_LOG}"
else
    echo "Error: Some partitions are missing on ${DEVICE}." | tee -a "${INSTALL_LOG}"
    sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc "${DEVICE}" >> "${INSTALL_LOG}"
    read -p "Press any key to exit..."
    exit 1
fi

# Check if 'OPL' is found in the 'lsblk' output and if it matches the device
if ! lsblk -p -o NAME,LABEL | grep -q "${DEVICE}3"; then
    echo "Error: APA-Jail failed on ${DEVICE}." | tee -a "${INSTALL_LOG}"
    read -p "Press any key to exit..."
    exit 1
fi

OPL_DEVICE="${DEVICE: -3}3"

PHY_SEC=$(lsblk -o NAME,PHY-SEC | grep $OPL_DEVICE | tr -s ' ' | cut -d' ' -f2)

# Check if PHY_SEC is 512
if [[ "$PHY_SEC" != "512" ]]; then
    echo "    ##########################################################################################"
    echo "    #  Unfortunately, your drive is not compatible with OPL.                                 #"
    echo "    #                                                                                        #"
    echo "    #  The physical sector size is $PHY_SEC; it must be 512. To resolve this issue, you can:     #"
    echo "    #                                                                                        #"
    echo "    #  1. Try connecting the PS2 HDD/SSD directly to your PC via an internal SATA connection #"
    echo "    #     or use a different USB adapter, and then run the PSBBN installer again.            #"
    echo "    #                                                                                        #"
    echo "    #  2. Try a different HDD/SSD and run the PSBBN installer again.                         #"
    echo "    #                                                                                        #"
    echo "    ##########################################################################################"
    echo "Error: Phystical Sector Size is: $PHY_SEC" >> "${INSTALL_LOG}"
    read -p "Press any key to exit..."
    exit 1
else
    echo "PHY-SEC value for $OPL_DEVICE is $PHY_SEC and valid. PSBBN successfully installed." | tee -a "${INSTALL_LOG}"
fi

read -p "Press any key to exit. "
