#!/bin/bash
# Set terminal size: 100 columns and 40 rows
echo -e "\e[8;40;100t"

# Set paths
TOOLKIT_PATH="$(pwd)"
ICONS_DIR="${TOOLKIT_PATH}/icons"
ARTWORK_DIR="${ICONS_DIR}/art"
HELPER_DIR="${TOOLKIT_PATH}/helper"
ASSETS_DIR="${TOOLKIT_PATH}/assets"
POPSTARTER="${ASSETS_DIR}/POPStarter/POPSTARTER.ELF"
NEUTRINO_DIR="${ASSETS_DIR}/neutrino"
LOG_FILE="${TOOLKIT_PATH}/game-installer.log"
MISSING_ART=${TOOLKIT_PATH}/missing-art.log
MISSING_APP_ART=${TOOLKIT_PATH}/missing-app-art.log


# Modify this path if your games are stored in a different location:
GAMES_PATH="${TOOLKIT_PATH}/games"

POPS_FOLDER="${GAMES_PATH}/POPS"
PS1_LIST="${TOOLKIT_PATH}/ps1.list"
PS2_LIST="${TOOLKIT_PATH}/ps2.list"
ALL_GAMES="${TOOLKIT_PATH}/master.list"

clear

cd "${TOOLKIT_PATH}"

# Check if the helper files exists
if [[ ! -f "${HELPER_DIR}/PFS Shell.elf" || ! -f "${HELPER_DIR}/HDL Dump.elf" ]]; then
    echo "Required helper files not found. Please ensure you are in the 'PSBBN-Definitive-English-Patch'"
    echo "directory and try again."
    exit 1
fi

echo "########################################################################################################">> "${LOG_FILE}";

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Cannot write to log file."
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

date >> "${LOG_FILE}"
echo >> "${LOG_FILE}"
cat /etc/*-release >> "${LOG_FILE}" 2>&1
echo >> "${LOG_FILE}"
echo "Path set to: $TOOLKIT_PATH" >> "${LOG_FILE}"
echo "Helper files found." >> "${LOG_FILE}"

# Check if the Python virtual environment exists
if [ -f "./venv/bin/activate" ]; then
    echo "The Python virtual environment exists." >> "${LOG_FILE}"
else
    echo "Error: The Python virtual environment does not exist. Run 01-Setup.sh and try again." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
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
      git pull --ff-only >> "${LOG_FILE}" 2>&1
      if [[ $? -ne 0 ]]; then
        echo
        echo "Error: Update failed. Delete the PSBBN-Definitive-English-Patch directory and run the command:"
        echo
        echo "git clone https://github.com/CosmicScale/PSBBN-Definitive-English-Patch.git"
        echo
        read -n 1 -s -r -p "Then try running the script again. Press any key to exit"
        echo
        exit 1
      fi
      echo
      echo "The repository has been successfully updated." | tee -a "${LOG_FILE}"
      read -n 1 -s -r -p "Press any key to exit, set your custom game path if required, then run the script again."
      echo
      exit 0
    else
      echo "The repository is up to date." | tee -a "${LOG_FILE}"
    fi
  fi
fi

function clean_up() {
# Loop through all items in the target directory
for item in "$ICONS_DIR"/*; do
    # Check if the item is a directory and not the 'art' folder
    if [ -d "$item" ] && [ "$(basename "$item")" != "art" ]; then
        rm -rf "$item" >> "${LOG_FILE}" 2>&1
    fi
done

# Find and delete all subdirectories in APPS direcrtory
while IFS= read -r dir; do
    rm -rf -- "$dir"
done < <(find "${GAMES_PATH}/APPS" -mindepth 1 -maxdepth 1 -type d | sort -r)

rm -f "${TOOLKIT_PATH}/package.json" >> "${LOG_FILE}" 2>&1
rm -f "${TOOLKIT_PATH}/package-lock.json" >> "${LOG_FILE}" 2>&1
rm -f "${PS1_LIST}" >> "${LOG_FILE}" 2>&1
rm -f "${PS2_LIST}" >> "${LOG_FILE}" 2>&1
rm -f "${ALL_GAMES}" >> "${LOG_FILE}" 2>&1
rm -f "${ARTWORK_DIR}/tmp"/* >> "${LOG_FILE}" 2>&1
}

clean_up
rm -f $MISSING_ART 2>>"${LOG_FILE}"
rm -f $MISSING_APP_ART 2>>"${LOG_FILE}"

echo "                  _____                        _____          _        _ _           ";
echo "                 |  __ \                      |_   _|        | |      | | |          ";
echo "                 | |  \/ __ _ _ __ ___   ___    | | _ __  ___| |_ __ _| | | ___ ___ ";
echo "                 | | __ / _\` | '_ \` _ \ / _ \   | || '_ \/ __| __/ _\` | | |/ _ \ __|";
echo "                 | |_\ \ (_| | | | | | |  __/  _| || | | \__ \ || (_| | | |  __/ |    ";
echo "                  \____/\__,_|_| |_| |_|\___|  \___/_| |_|___/\__\__,_|_|_|\___|_|    ";
echo "                                                                      ";
echo "                                         Written by CosmicScale"
echo
echo "   ##############################################################################################"
echo "   #  This tool synchronizes the games on your PC with those on your PS2's HDD/SSD.             #"
echo "   #                                                                                            #"
echo "   #  Ensure the PS2 drive is connected to your PC before proceeding.                           #"
echo "   #                                                                                            #"
echo "   #  How Syncing Works:                                                                        #"
echo "   #                                                                                            #"
echo "   #  Copying: Games in your PC's 'games' folder that are missing from your PS2 will be added   #"
echo "   #                                                                                            #"
echo "   #  Removal: Games on your PS2 that are not in your PC's 'games' folder will be removed.      #"
echo "   #                                                                                            #"
echo "   ##############################################################################################"
echo
read -n 1 -s -r -p "   Press any key to continue..."
echo

# Choose the PS2 storage device
while true; do
clear
echo
echo "                  _____                        _____          _        _ _           ";
echo "                 |  __ \                      |_   _|        | |      | | |          ";
echo "                 | |  \/ __ _ _ __ ___   ___    | | _ __  ___| |_ __ _| | | ___ ___ ";
echo "                 | | __ / _\` | '_ \` _ \ / _ \   | || '_ \/ __| __/ _\` | | |/ _ \ __|";
echo "                 | |_\ \ (_| | | | | | |  __/  _| || | | \__ \ || (_| | | |  __/ |    ";
echo "                  \____/\__,_|_| |_| |_|\___|  \___/_| |_|___/\__\__,_|_|_|\___|_|    ";
echo "                                                                      ";
echo "                                         Written by CosmicScale"
    echo | tee -a "${LOG_FILE}"
    lsblk -p -o MODEL,NAME,SIZE,LABEL,MOUNTPOINT | tee -a "${LOG_FILE}"
    echo | tee -a "${LOG_FILE}"
        
    read -p "Choose your PS2 HDD from the list above (e.g., /dev/sdx): " DEVICE
        
    # Check if the device exists and is valid
    if [[ -n "$DEVICE" ]] && lsblk -dp -n -o NAME | grep -q "^$DEVICE$"; then
        echo
        echo -e "Selected drive: \"${DEVICE}\"" | tee -a "${LOG_FILE}"

        # Run HDL Dump and capture output
        output=$(sudo "${TOOLKIT_PATH}"/helper/HDL\ Dump.elf toc ${DEVICE} 2>&1)
        # Check for the word "aborting" in the output
        if echo "$output" | grep -qE "aborting|No medium found"; then
            echo
            echo "Error: APA partition is broken on ${DEVICE}." | tee -a "${LOG_FILE}"
            read -n 1 -s -r -p "Press any key to exit..."
            echo
            exit 1
        fi
        
        # Check if 'OPL' is found in the 'lsblk' output and if it matches the device
        lsblk_output=$(lsblk -p -o NAME,LABEL | sed 's/[├└─]//g')
        echo >> "${LOG_FILE}"
        echo "$lsblk_output" >> "${LOG_FILE}"

        if ! echo "$lsblk_output" | awk -v part="${DEVICE}3" '$1 == part && $2 == "OPL"' | grep -q .; then
            echo "Error: OPL partition not found on ${DEVICE}" | tee -a "${LOG_FILE}"
            read -n 1 -s -r -p "Press any key to exit..."
            echo
            exit 1
        fi

        break
    else
        echo
        echo "Error: Invalid input. Please enter a valid device name (e.g., /dev/sdx)."
        read -n 1 -s -r -p "Press any key to try again..."
        echo
    fi
done

# Find all mounted volumes associated with the device
mounted_volumes=$(lsblk -ln -o MOUNTPOINT "$DEVICE" | grep -v "^$")

# Iterate through each mounted volume and unmount it
echo | tee -a "${LOG_FILE}"
echo "Unmounting volumes associated with $DEVICE..."
for mount_point in $mounted_volumes; do
    echo "Unmounting $mount_point..." | tee -a "${LOG_FILE}"
    if sudo umount "$mount_point"; then
        echo "Successfully unmounted $mount_point." | tee -a "${LOG_FILE}"
    else
        echo "Failed to unmount $mount_point. Please unmount manually." | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
done

echo "All volumes unmounted for $DEVICE."| tee -a "${LOG_FILE}"

# Validate the GAMES_PATH
if [[ ! -d "$GAMES_PATH" ]]; then
    echo
    echo "Error: GAMES_PATH is not a valid directory: $GAMES_PATH" | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo | tee -a "${LOG_FILE}"
echo "GAMES_PATH is valid: $GAMES_PATH" | tee -a "${LOG_FILE}"

# Create necessary folders if they don't exist
for folder in APPS ART CFG CHT LNG THM VMC POPS CD DVD; do
    dir="${GAMES_PATH}/${folder}"
    [[ -d "$dir" ]] || mkdir -p "$dir" || { 
        echo "Error: Failed to create $dir. Make sure you have write permissions to $GAMES_PATH" | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    }
done

# Check if GAMES_PATH is custom
if [[ "${GAMES_PATH}" != "${TOOLKIT_PATH}/games" ]]; then
    echo | tee -a "${LOG_FILE}"
    echo "Using custom game path." | tee -a "${LOG_FILE}"
    cp "${TOOLKIT_PATH}/games/APPS/BOOT.ELF" "${TOOLKIT_PATH}/games/APPS/Launch-Disc.elf" "${GAMES_PATH}/APPS" >> "${LOG_FILE}" 2>&1
else
    echo | tee -a "${LOG_FILE}"
    echo "Using default game path." | tee -a "${LOG_FILE}"
fi

mkdir -p "${ICONS_DIR}/bbnl"

echo | tee -a "${LOG_FILE}"
echo "Please choose a game launcher:"
echo "1) Open PS2 Loader (OPL)"
echo "2) Neutrino"
echo

while true; do
    read -p "Enter 1 or 2: " choice
    case "$choice" in
        1) LAUNCHER="OPL"; DESC="Open PS2 Loader (OPL)";;
        2) LAUNCHER="NEUTRINO"; DESC="Neutrino";;
        *) echo; echo "Invalid choice. Please enter 1 or 2."; continue ;;
    esac

    echo
    read -p "You selected $DESC. Are you sure? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && break  # Exit loop if "y"
done

echo "$DESC selected." >> "${LOG_FILE}"
echo  >> "${LOG_FILE}"

# Delete old game partitions
delete_partition=$(sudo "${HELPER_DIR}/HDL Dump.elf" toc "$DEVICE" | grep -o 'PP\.[^ ]\+')
COMMANDS="device ${DEVICE}\n"

while IFS= read -r partition; do
    COMMANDS+="rmpart ${partition}\n"
done <<< "$delete_partition"

COMMANDS+="rmpart +OPL\n"
COMMANDS+="exit"

echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1

echo | tee -a "${LOG_FILE}"

echo "Preparing to sync apps..." | tee -a "${LOG_FILE}"

cd "${GAMES_PATH}/APPS"

# Check if any .psu or .PSU files exist in the source directory
if find "${GAMES_PATH}/APPS/" -maxdepth 1 -type f \( -name "*.psu" -o -name "*.PSU" \) | grep -q .; then
    echo | tee -a "${LOG_FILE}"
    echo "Processing PSU files:" | tee -a "${LOG_FILE}"
    # Process each .psu file in the source directory
        for file in "${GAMES_PATH}/APPS/"*.psu "${GAMES_PATH}/APPS/"*.PSU; do
        [ -e "$file" ] || continue  # Skip if no PSU files exist
    
        echo "Extracting $file..."
        "${HELPER_DIR}/PSU Extractor.elf" "$file" >> "${LOG_FILE}" 2>&1
       done

    for dir in */; do
    [[ -d "$dir" ]] || continue

    # Check for .elf/.ELF file
    if find "$dir" -maxdepth 1 -type f \( -iname "*.elf" \) | grep -q . && \
        [[ -f "$dir/icon.sys" && -f "$dir/title.cfg" ]]; then
        cp -r "$dir" "${ICONS_DIR}"
    fi
    done

    # Loop through each folder in DST_DIR, excluding 'art', sorted in reverse alphabetical order
    find "$ICONS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "art" ! -name "bbnl" | sort -r | while IFS= read -r dir; do

    folder_name=$(basename "$dir")

    # Find the first .ELF file in the extracted directory
    elf_file=$(find "$dir" -maxdepth 1 -type f -iname "*.elf" | head -n 1)
    # Extract only the filename if an ELF file was found
    elf_filename=$(basename "$elf_file")
    echo | tee -a "${LOG_FILE}"
    echo "Found ELF file: $elf_filename" | tee -a "${LOG_FILE}"

    if [ -f "$dir/list.icn" ]; then
        mv "$dir/list.icn" "$dir/list.ico" 2>> "${LOG_FILE}"
        [ -f "$dir/del.icn" ] && mv "$dir/del.icn" "$dir/del.ico" 2>> "${LOG_FILE}"
        echo "list.icn found in $dir, converted to list.ico" | tee -a "${LOG_FILE}"
    else
        echo "list.icn not found in $dir, using default icon." | tee -a "${LOG_FILE}"
        cp "${ASSETS_DIR}/app-list.ico" "$dir/list.ico" 2>> "${LOG_FILE}"
        cp "${ASSETS_DIR}/app-del.ico" "$dir/del.ico" 2>> "${LOG_FILE}"
    fi

    # Convert the icon.sys file
    icon_sys_filename="$dir/icon.sys"

    python3 "${HELPER_DIR}/icon_sys_to_txt.py" "$icon_sys_filename" >> "${LOG_FILE}" 2>&1
    mv "$dir/icon.txt" "$icon_sys_filename"

    if [ $? -ne 0 ]; then
        echo "Failed to convert icon.sys: $icon_sys_filename" | tee -a "${LOG_FILE}"
    else
        echo "Converted icon.sys: $icon_sys_filename"  | tee -a "${LOG_FILE}"
    fi

    while IFS='=' read -r key value; do
        key=$(echo "$key" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Remove non-ASCII and non-printable characters
        value=$(printf '%s' "$value" | LC_ALL=C tr -cd '\40-\176')

        case "$key" in
            title) title="$value" ;;
            boot) elf="$value" ;;
            Developer) developer="$value" ;;
        esac
    done < "$dir/title.cfg"

# Generate the info.sys file
    info_sys_filename="$dir/info.sys"
    cat > "$info_sys_filename" <<EOL
title = $title
title_id = $folder_name
title_sub_id = 0
release_date = 
developer_id = 
publisher_id = $developer
note = 
content_web = 
image_topviewflag = 0
image_type = 0
image_count = 1
image_viewsec = 600
copyright_viewflag = 0
copyright_imgcount = 0
genre = 
parental_lock = 1
effective_date = 0
expire_date = 0
violence_flag = 0
content_type = 255
content_subtype = 0
EOL
    echo "Created info.sys: $info_sys_filename"  | tee -a "${LOG_FILE}"

    # Generate the bbnl cfg file
    bbnl_filename="${ICONS_DIR}/bbnl/$folder_name.cfg"
    cat > "$bbnl_filename" <<EOL
file_name=/APPS/$folder_name/$elf_filename
title_id=$folder_name
launcher=ELF
EOL
    echo "Created bbnl config: $bbnl_filename"  | tee -a "${LOG_FILE}"

    png_file="${ARTWORK_DIR}/${folder_name}.png"
    # Copy the matching PNG file from ART_DIR, or default to APP.png
    if [ -f "$png_file" ]; then
        cp "$png_file" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
        cp "$png_file" "${GAMES_PATH}/ART/${elf}_COV.png" | tee -a "${LOG_FILE}"
        echo "Artwork found locally for $title"  | tee -a "${LOG_FILE}"
    else
        echo "Artwork not found locally. Attempting to download from the PSBBN art database..." | tee -a "${LOG_FILE}"
        wget --quiet --timeout=10 --tries=3 --output-document="$png_file" \
        "https://raw.githubusercontent.com/CosmicScale/psbbn-art-database/main/apps/${folder_name}.png"
            if [[ -s "$png_file" ]]; then
                echo "Successfully downloaded artwork for $folder_name" | tee -a "${LOG_FILE}"
                cp "$png_file" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
                cp "$png_file" "${GAMES_PATH}/ART/${elf}_COV.png" | tee -a "${LOG_FILE}"
            else
                rm -f "$png_file"
                echo "Artwork not found for $folder_name. Using default APP image." | tee -a "${LOG_FILE}"
                cp "$ARTWORK_DIR/APP.png" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
                echo "$folder_name,$title,$elf" >> "${MISSING_APP_ART}"
            fi
    fi

    cp "${ASSETS_DIR}/BBNL"/{boot.kelf,system.cnf} "$dir"

    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mkpart PP.$folder_name 128M PFS\n"
    COMMANDS+="mount PP.$folder_name\n"
    COMMANDS+="mkdir res\n"
    COMMANDS+="cd res\n"
    COMMANDS+="lcd '${ICONS_DIR}/$folder_name'\n"
    COMMANDS+="put info.sys\n"
    COMMANDS+="put jkt_001.png\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    echo "Creating PP.$folder_name..." | tee -a "${LOG_FILE}"
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1
    cd "${ICONS_DIR}/$folder_name"
    sudo "${HELPER_DIR}/HDL Dump.elf" modify_header "${DEVICE}" "PP.$folder_name" >> "${LOG_FILE}" 2>&1

    done

else
    echo | tee -a "${LOG_FILE}"
    echo "No PSU files found." | tee -a "${LOG_FILE}"
fi

existing_folders=()

# Get all directories and add them to the exclusion list
while IFS= read -r dir; do
    folder_name=$(basename "$dir")
    existing_folders+=("$folder_name")
done < <(find "$ICONS_DIR" -mindepth 1 -maxdepth 1 -type d | sort -r)

# Build the exclusion conditions dynamically based on the existing_folders array
exclude_conditions=()
for folder in "${existing_folders[@]}"; do
    exclude_conditions+=("-not" "-name" "$folder")
done

# Check if any ELF files exist in the source directory
if ! ls "${GAMES_PATH}/APPS/"*.elf "${GAMES_PATH}/APPS/"*.ELF >/dev/null 2>&1; then
    echo | tee -a "${LOG_FILE}"
    echo "No ELF files found." | tee -a "${LOG_FILE}"
else
    # Process each ELF file in the source directory
    echo | tee -a "${LOG_FILE}"
    echo "Processing ELF files:"| tee -a "${LOG_FILE}"
    for file in "${GAMES_PATH}/APPS/"*.elf "${GAMES_PATH}/APPS/"*.ELF; do
        [ -e "$file" ] || continue  # Skip if no ELF files exist
        # Extract filename without path and extension
        base_name=$(basename "$file")
        base_name_no_ext="${base_name%.*}"
        echo | tee -a "${LOG_FILE}"
        echo "Found ELF file: $base_name" | tee -a "${LOG_FILE}"

        app_name="${base_name_no_ext%%(*}" # Remove anything after an open bracket '('
        app_name="${app_name%%[Vv][0-9]*}" # Remove versioning (e.g., v12 or V12)
        app_name=$(echo "$app_name" | sed -E 's/[cC][oO][mM][pP][rR][eE][sS][sS][eE][dD].*//') # Remove "compressed"
        app_name=$(echo "$app_name" | sed -E 's/[pP][aA][cC][kK][eE][dD].*//') # Remove "packed"
        app_name=$(echo "$app_name" | sed 's/\.*$//') # Trim trailing full stops

        AppDB_check=$(echo "$app_name" | sed 's/[ _-]//g' | tr 'a-z' 'A-Z')

        # Check $HELPER_DIR/AppDB.csv for match in first column to $AppDB_check, set $cleaned_name based on second column from file if found. If no match found, set $cleaned_name with the remaining code
        match=$(awk -F'|' -v key="$AppDB_check" '$1 && index(key, $1) == 1 {print $2; exit}' "$HELPER_DIR/AppDB.csv")

        if [[ -n "$match" ]]; then
            cleaned_name="$match"
        else
            # Use the processed name if no match is found
            app_name="${app_name//[_-]/ }"  # Replace underscores and hyphens with spaces
            app_name="${app_name%"${app_name##*[![:space:]]}"}" # Trim trailing spaces again
            app_name=$(echo "$app_name" | sed 's/\.*$//') # Trim trailing full stops again
            app_name_before=$(echo "$app_name") # Save the string
            app_name=$(echo "$app_name" | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g') # Add a space before capital letters when preceded by a lowercase letter

            # Check if spaces were added by comparing before and after
            if [[ "$app_name" != "$app_name_before" ]]; then
                space_added=true
            else
                space_added=false
            fi

            # Process for title case and exceptions
            input_str="$app_name"

            # List of terms to ensure spaces before and after
            terms=("3d" "3D" "ps2" "PS2" "ps1" "PS1")
    
            # Loop over the terms
            for term in "${terms[@]}"; do
                input_str="${input_str//${term}/ ${term}}"  # Ensure space before the term
                input_str="${input_str//${term}/${term} }"  # Ensure space after the term
            done

            # Special case for "hdd" and "HDD" - add spaces only if the string is longer than 5 characters
            if [[ ${#input_str} -gt 5 ]]; then
                input_str="${input_str//hdd/ hdd }"
                input_str="${input_str//HDD/ HDD }"
            fi

            # Check if the string contains any lowercase letters
            if ! echo "$input_str" | grep -q '[a-z]'; then
                input_str="${input_str,,}"  # Convert the entire string to lowercase
            fi

            result=""
            # Define words to exclude from uppercase conversion (only consonant-only words)
            exclude_list="by cry cyst crypt dry fly fry glyph gym gypsy hymn lynx my myth myrrh ply pry rhythm shy sky spy sly sty sync tryst why wry"

            # Now process each word
            for word in $input_str; do
                # Handle words 3 characters or shorter, but only if no space was added by sed
                if [[ ${#word} -le 3 ]] && ! $space_added && ! echo "$exclude_list" | grep -wi -q "$word"; then
                    result+=" ${word^^}"  # Convert to uppercase
                # Handle consonant-only words (only if not in exclusion list)
                elif [[ "$word" =~ ^[b-df-hj-np-tv-z0-9]+$ ]] && ! echo "$exclude_list" | grep -w -q "$word"; then
                    result+=" ${word^^}"  # Uppercase if the word is consonant-only and not in the exclusion list
                else
                    result+=" ${word^}"  # Capitalize first letter for all other words
                fi

            cleaned_name="${result# }"
            done

            # Remove leading space and ensure no double spaces are left
            result="${result#"${result%%[![:space:]]*}"}"  # Remove leading spaces
            cleaned_name=$(echo "$result" | sed 's/  / /g')  # Replace double spaces with single spaces
        fi

        folder_name=$(echo "$cleaned_name" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-11)  # Replace spaces with underscores & capitalize

        # Create the new folder in the destination directory
        mkdir -p "${ICONS_DIR}/$folder_name"

        # Generate the icon.sys file
        icon_sys_filename="${ICONS_DIR}/$folder_name/icon.sys"
        cat > "$icon_sys_filename" <<EOL
PS2X
title0=$cleaned_name
title1=
bgcola=90
bgcol0=192,192,192
bgcol1=102,102,102
bgcol2=40,40,40
bgcol3=0,0,0
lightdir0=0.5000,0.5000,0.5000
lightdir1=0.0000,-0.4000,-0.1000
lightdir2=-0.5000,-0.5000,0.5000
lightcolamb=63,63,63
lightcol0=61,61,3
lightcol1=63,42,25
lightcol2=17,17,48
uninstallmes0=
uninstallmes1=
uninstallmes2=
EOL
        echo "Created icon.sys: $icon_sys_filename"  | tee -a "${LOG_FILE}"

        # Generate the info.sys file
        if [[ "$cleaned_name" == "PSBBN" ]]; then
            info_sys_filename="${ICONS_DIR}/$folder_name/info.sys"
            cat > "$info_sys_filename" <<EOL
title = $cleaned_name
title_id = $folder_name
title_sub_id = 0
release_date = 
developer_id = 
publisher_id = 
note = 
content_web = 
image_topviewflag = 0
image_type = 0
image_count = 1
image_viewsec = 600
copyright_viewflag = 0
copyright_imgcount = 0
genre = 
parental_lock = 1
effective_date = 0
expire_date = 0
violence_flag = 0
content_type = 256
content_subtype = 0
EOL
        else
            info_sys_filename="${ICONS_DIR}/$folder_name/info.sys"
            cat > "$info_sys_filename" <<EOL
title = $cleaned_name
title_id = $folder_name
title_sub_id = 0
release_date = 
developer_id = 
publisher_id = 
note = 
content_web = 
image_topviewflag = 0
image_type = 0
image_count = 1
image_viewsec = 600
copyright_viewflag = 0
copyright_imgcount = 0
genre = 
parental_lock = 1
effective_date = 0
expire_date = 0
violence_flag = 0
content_type = 255
content_subtype = 0
EOL
            echo "Created info.sys: $info_sys_filename"  | tee -a "${LOG_FILE}"
        fi

        if [[ "$folder_name" == "LAUNCHELF" ]]; then
            bbnl_cfg="${ICONS_DIR}/bbnl/WLE.cfg"
        elif [[ "$folder_name" == "LAUNCHDISC" ]]; then
            bbnl_cfg="${ICONS_DIR}/bbnl/DISC.cfg"
        else
            bbnl_cfg="$ICONS_DIR/bbnl/$folder_name.cfg"
        fi
        cat > "$bbnl_cfg" <<EOL
file_name=/APPS/$base_name
title_id=$folder_name
launcher=ELF
EOL
        echo "Created BBNL config: $folder_name.cfg"  | tee -a "${LOG_FILE}"
        echo "$cleaned_name=mass:/APPS/$base_name" >> "${ICONS_DIR}/bbnl/conf_apps.cfg" 2>> "${LOG_FILE}"

        cp "${ASSETS_DIR}/BBNL/boot.kelf" "${ICONS_DIR}/$folder_name" | tee -a "${LOG_FILE}"
        cp "${ASSETS_DIR}/app-list.ico" "${ICONS_DIR}/$folder_name/list.ico" | tee -a "${LOG_FILE}"
        cp "${ASSETS_DIR}/app-del.ico" "${ICONS_DIR}/$folder_name/del.ico" | tee -a "${LOG_FILE}"
        cp "${ASSETS_DIR}/BBNL/system.cnf" "${ICONS_DIR}/$folder_name" | tee -a "${LOG_FILE}"

        png_file="${ARTWORK_DIR}/${folder_name}.png"
        # Copy the matching PNG file from ART_DIR, or default to APP.png
        if [ -f "$png_file" ]; then
            cp "$png_file" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
            cp "$png_file" "${GAMES_PATH}/ART/${base_name}_COV.png" | tee -a "${LOG_FILE}"
            echo "Artwork found locally for $base_name"  | tee -a "${LOG_FILE}"
        else
            echo "Artwork not found locally. Attempting to download from the PSBBN art database..." | tee -a "${LOG_FILE}"
            wget --quiet --timeout=10 --tries=3 --output-document="$png_file" \
            "https://raw.githubusercontent.com/CosmicScale/psbbn-art-database/main/apps/${folder_name}.png"
                if [[ -s "$png_file" ]]; then
                    echo "Successfully downloaded artwork for $base_name" | tee -a "${LOG_FILE}"
                    cp "$png_file" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
                    cp "$png_file" "${GAMES_PATH}/ART/${base_name}_COV.png" | tee -a "${LOG_FILE}"
                else
                    rm -f "$png_file"
                    echo "Artwork not found for $base_name. Using default APP image." | tee -a "${LOG_FILE}"
                    cp "$ARTWORK_DIR/APP.png" "${ICONS_DIR}/$folder_name/jkt_001.png" | tee -a "${LOG_FILE}"
                    if [[ "$folder_name" != "PSBBN" ]]; then
                        echo "$folder_name,$cleaned_name,$base_name" >> "${MISSING_APP_ART}"
                    fi
                fi
        fi
    done
fi

echo | tee -a "${LOG_FILE}"

# Loop through each folder in ICONS_DIR, excluding folders that have already been processed, sorted in reverse alphabetical order
find "$ICONS_DIR" -mindepth 1 -maxdepth 1 -type d "${exclude_conditions[@]}" | sort -r | while IFS= read -r dir; do
    COMMANDS="device ${DEVICE}\n"
    # Set pp_name based on the folder name
    if [[ "$(basename "$dir")" == "LAUNCHELF" ]]; then
        pp_name="WLE"
    elif [[ "$(basename "$dir")" == "LAUNCHDISC" ]]; then
        pp_name="DISC"
    else
        pp_name=$(basename "$dir")
    fi
    COMMANDS+="mkpart PP.$pp_name 128M PFS\n"
    COMMANDS+="mount PP.$pp_name\n"
    if [ "$pp_name" = "DISC" ]; then
        COMMANDS+="lcd '${ASSETS_DIR}/DISC'\n"
        COMMANDS+="put PS1VModeNeg.elf\n"
    fi
    COMMANDS+="mkdir res\n"
    COMMANDS+="cd res\n"
    COMMANDS+="lcd '${ICONS_DIR}/$(basename "$dir")'\n"
    COMMANDS+="put info.sys\n"
    COMMANDS+="put jkt_001.png\n"
    COMMANDS+="cd /\n"
    COMMANDS+="umount\n"
    COMMANDS+="exit"

    echo "Creating PP.$pp_name..." | tee -a "${LOG_FILE}"
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1
    cd "${ICONS_DIR}/$(basename "$dir")"
    sudo "${HELPER_DIR}/HDL Dump.elf" modify_header "${DEVICE}" "PP.$pp_name" >> "${LOG_FILE}" 2>&1

    if [ "$pp_name" = "DISC" ]; then
        cd "${ASSETS_DIR}/DISC"
        sudo "${HELPER_DIR}/HDL Dump.elf" modify_header "${DEVICE}" "PP.$pp_name" >> "${LOG_FILE}" 2>&1
    fi
done

# Create PP.LAUNCHER
echo | tee -a "${LOG_FILE}"
echo "Updating chosen game launcher..." | tee -a "${LOG_FILE}"
COMMANDS="device ${DEVICE}\n"
COMMANDS+="mkpart PP.LAUNCHER 128M PFS\n"
COMMANDS+="mount PP.LAUNCHER\n"
COMMANDS+="mkdir res\n"
COMMANDS+="cd res\n"

if [ "$LAUNCHER" = "OPL" ]; then
    COMMANDS+="lcd '${ASSETS_DIR}/OPL'\n"
    COMMANDS+="put info.sys\n"
    COMMANDS+="lcd '${ARTWORK_DIR}'\n"
    COMMANDS+="put OPENPS2LOAD.png\n"
    COMMANDS+="rename OPENPS2LOAD.png jkt_001.png\n"
    COMMANDS+="cd /\n"
elif [ "$LAUNCHER" = "NEUTRINO" ]; then
    COMMANDS+="lcd '${ASSETS_DIR}/NHDDL'\n"
    COMMANDS+="put info.sys\n"
    COMMANDS+="lcd '${ARTWORK_DIR}'\n"
    COMMANDS+="put NHDDL.png\n"
    COMMANDS+="rename NHDDL.png jkt_001.png\n"
    COMMANDS+="cd /\n"
fi

COMMANDS+="umount\n"
COMMANDS+="exit"

echo >> "${LOG_FILE}"
echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1


if [ "$LAUNCHER" = "OPL" ]; then
    cp "${ASSETS_DIR}/BBNL/boot.kelf" "${ASSETS_DIR}/BBNL/system.cnf" "${ASSETS_DIR}/OPL"
    cd "${ASSETS_DIR}/OPL"
elif [ "$LAUNCHER" = "NEUTRINO" ]; then
    cp "${ASSETS_DIR}/BBNL/boot.kelf" "${ASSETS_DIR}/BBNL/system.cnf" "${ASSETS_DIR}/NHDDL"
    cd "${ASSETS_DIR}/NHDDL"
fi

sudo "${HELPER_DIR}/HDL Dump.elf" modify_header "${DEVICE}" PP.LAUNCHER >> "${LOG_FILE}" 2>&1

cd "${TOOLKIT_PATH}"

echo | tee -a "${LOG_FILE}"

echo "Activating Python virtual environment..." | tee -a "${LOG_FILE}"
sleep 5

# Try activating the virtual environment twice before failing
if ! source "${TOOLKIT_PATH}/venv/bin/activate" 2>>"${LOG_FILE}"; then
    echo "Failed to activate the Python virtual environment. Retrying..." | tee -a "${LOG_FILE}"
    sleep 2
    
    if ! source "${TOOLKIT_PATH}/venv/bin/activate" 2>>"${LOG_FILE}"; then
        echo "Failed to activate the Python virtual environment." | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
fi

if [[ "$LAUNCHER" == "NEUTRINO" ]]; then
    if find "$GAMES_PATH/CD" "$GAMES_PATH/DVD" -type f \( -iname "*.zso" \) | grep -q .; then
        echo | tee -a "${LOG_FILE}"
        echo "Games in the compressed ZSO format have been found in the CD/DVD folder." | tee -a "${LOG_FILE}"
        echo "Neutrino does not support compressed ZSO files."
        echo
        echo "ZSO files will be converted to ISO files before proceeding."
        read -n 1 -s -r -p "Press any key to continue..."
        echo
        echo

        while IFS= read -r -d '' zso_file; do
            iso_file="${zso_file%.*}.iso"
            echo "Converting: $zso_file -> $iso_file" | tee -a "${LOG_FILE}"

            python3 -u "${HELPER_DIR}/ziso.py" -c 0 "$zso_file" "$iso_file" | tee -a "${LOG_FILE}"
            if [ "${PIPESTATUS[0]}" -ne 0 ]; then
                rm -f "$iso_file"
                echo "Error: Failed to uncompress $zso_file" | tee -a "${LOG_FILE}"
                read -n 1 -s -r -p "Press any key to exit..."
                echo
                exit 1  # Properly exits the main script
            fi

            rm -f "$zso_file"
        done < <(find "$GAMES_PATH/CD" "$GAMES_PATH/DVD" -type f -iname "*.zso" -print0)
    fi
fi

# Create games list of PS1 and PS2 games to be installed
echo | tee -a "${LOG_FILE}"
echo "Creating PS1 games list..." | tee -a "${LOG_FILE}"
python3 -u "${HELPER_DIR}/list-builder-ps1.py" "${GAMES_PATH}" "${PS1_LIST}" | tee -a "${LOG_FILE}"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "Error: Failed to create PS1 games list." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo | tee -a "${LOG_FILE}"
echo "Creating PS2 games list..." | tee -a "${LOG_FILE}"
python3 -u "${HELPER_DIR}/list-builder-ps2.py" "${GAMES_PATH}" "${PS2_LIST}" | tee -a "${LOG_FILE}"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "Error: Failed to create PS2 games list." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Deactivate the virtual environment
deactivate

# Create master list combining PS1 and PS2 games to a single list
if [[ ! -f "${PS1_LIST}" && ! -f "${PS2_LIST}" ]]; then
    echo
    read -n 1 -s -r -p "No games found to install. Press any key to exit..."
    echo
    exit 1
elif [[ ! -f "${PS1_LIST}" ]]; then
    { cat "${PS2_LIST}" > "${ALL_GAMES}"; } 2>> "${LOG_FILE}"
else
    { cat "${PS1_LIST}" > "${ALL_GAMES}"; } 2>> "${LOG_FILE}"
    { cat "${PS2_LIST}" >> "${ALL_GAMES}"; } 2>> "${LOG_FILE}"
fi

# Check for master.list
if [[ ! -s "${ALL_GAMES}" ]]; then
    echo "Failed to create games list (file is missing or empty)." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo "Games list successfully created."| tee -a "${LOG_FILE}"
    
# Function to find available space
function function_space() {

output=$(sudo "${HELPER_DIR}/HDL Dump.elf" toc ${DEVICE} 2>&1)

# Check for the word "aborting" in the output
if echo "$output" | grep -q "aborting"; then
    echo
    echo "${DEVICE}: APA partition is broken; aborting." | tee -a "${LOG_FILE}"
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

# Count the number of games to be installed
count=$(grep -c '^[^[:space:]]' "${ALL_GAMES}")
echo
echo "Number of games to install: $count" | tee -a "${LOG_FILE}"

function_space

partition_count=$((available / 128))

if [ "$count" -gt "$partition_count" ]; then

    echo "Not enough space for $count partitions." | tee -a "${LOG_FILE}"
    echo "The first $partition_count games will appear in the PSBBN Game Channel" | tee -a "${LOG_FILE}"
    echo "Remaining PS2 games will appear in OPL/NHDDL only"

    # Overwrite master.list with the first $partition_count lines
    head -n "$partition_count" "$ALL_GAMES" > "${ALL_GAMES}.tmp"
    mv "${ALL_GAMES}.tmp" "$ALL_GAMES"
fi

echo >> "${LOG_FILE}"
echo "master.list:" >> "${LOG_FILE}"
cat "$ALL_GAMES" >> "${LOG_FILE}"

echo | tee -a "${LOG_FILE}"
read -n 1 -s -r -p "Ready to install games. Press any key to continue..."
echo

mkdir -p "${ARTWORK_DIR}/tmp" 2>> "${LOG_FILE}"

echo | tee -a "${LOG_FILE}"
echo "Downloading artwork..."  | tee -a "${LOG_FILE}"

cd "${TOOLKIT_PATH}"

# First loop: Run the art downloader script for each game_id if artwork doesn't already exist
while IFS='|' read -r game_title game_id publisher disc_type file_name; do
  # Check if the artwork file already exists
  png_file="${ARTWORK_DIR}/${game_id}.png"
  if [[ -f "$png_file" ]]; then
    echo "Artwork for game ID $game_id already exists. Skipping download." | tee -a "${LOG_FILE}"
  else
    # Attempt to download artwork using wget
    echo "Artwork not found locally. Attempting to download from the PSBBN art database..." | tee -a "${LOG_FILE}"
    wget --quiet --timeout=10 --tries=3 --output-document="$png_file" \
        "https://raw.githubusercontent.com/CosmicScale/psbbn-art-database/main/art/${game_id}.png"
    if [[ -s "$png_file" ]]; then
      echo "Successfully downloaded artwork for game ID: $game_id" | tee -a "${LOG_FILE}"
    else
      # If wget fails, run the art downloader
        [[ -f "$png_file" ]] && rm -f "$png_file"
        echo "Trying IGN for game ID: $game_id" | tee -a "${LOG_FILE}"
        node "${HELPER_DIR}/art_downloader.js" "$game_id" 2>&1 | tee -a "${LOG_FILE}"
    fi
  fi

  # Skip downloading if disc_type is "POPS"
  if [[ "$disc_type" == "POPS" ]]; then
    continue
  fi

  png_file_cover="${GAMES_PATH}/ART/${game_id}_COV.png"
  png_file_disc="${GAMES_PATH}/ART/${game_id}_ICO.png"
  if [[ -f "$png_file_cover" ]]; then
    echo "OPL Artwork for game ID $game_id already exists. Skipping download." | tee -a "${LOG_FILE}"
  else
    # Attempt to download artwork using wget
    echo "OPL Artwork not found locally. Attempting to download from archive.org..." | tee -a "${LOG_FILE}"
    wget --quiet --timeout=10 --tries=3 --output-document="$png_file_cover" \
        "https://archive.org/download/OPLM_ART_2024_09/OPLM_ART_2024_09.zip/PS2/${game_id}/${game_id}_COV.png"
    #wget --quiet --timeout=10 --tries=3 --output-document="$png_file_disc" \
    #    "https://archive.org/download/OPLM_ART_2024_09/OPLM_ART_2024_09.zip/PS2/${game_id}/${game_id}_ICO.png"

    missing_files=()

    if [[ ! -s "$png_file_cover" ]]; then
        [[ -f "$png_file_cover" ]] && rm -f "$png_file_cover"
        missing_files+=("cover")
    fi

    if [[ ! -s "$png_file_disc" ]]; then
        [[ -f "$png_file_disc" ]] && rm -f "$png_file_disc"
        missing_files+=("disc")
    fi

    if [[ -f "$png_file_cover" || -f "$png_file_disc" ]]; then
        if [[ ${#missing_files[@]} -eq 0 ]]; then
            echo "Successfully downloaded OPL artwork for game ID: $game_id" | tee -a "${LOG_FILE}"
        else
            echo "Successfully downloaded some OPL artwork for game ID: $game_id, but missing: ${missing_files[*]}" | tee -a "${LOG_FILE}"
        fi
    else
        echo "Failed to download OPL artwork for game ID: $game_id" | tee -a "${LOG_FILE}"
    fi
  fi
done < "$ALL_GAMES"

echo | tee -a "${LOG_FILE}"
echo "Converting artwork..." | tee -a "${LOG_FILE}"

# Define input directory
input_dir="${ARTWORK_DIR}/tmp"

# Check if the directory contains any files
if compgen -G "${input_dir}/*" > /dev/null; then
    for file in "${input_dir}"/*; do
        # Extract the base filename without the path or extension
        base_name=$(basename "${file%.*}")

        # Define output filename with .png extension
        output="${ARTWORK_DIR}/tmp/${base_name}.png"

        # Get image dimensions using identify
        dimensions=$(identify -format "%w %h" "$file")
        width=$(echo "$dimensions" | cut -d' ' -f1)
        height=$(echo "$dimensions" | cut -d' ' -f2)

        # Check if width >= 256 and height >= width
        if [[ $width -ge 256 && $height -ge $width ]]; then
            # Determine whether the image is square
            if [[ $width -eq $height ]]; then
                # Square: Resize without cropping
                echo "Resizing square image $file"
                convert "$file" -resize 256x256! -depth 8 -alpha off "$output"
            else
                # Not square: Resize and crop
                echo "Resizing and cropping $file"
                convert "$file" -resize 256x256^ -crop 256x256+0+44 -depth 8 -alpha off "$output"
            fi
            rm -f "$file"
        else
            echo "Skipping $file: does not meet size requirements" | tee -a "${LOG_FILE}"
            rm -f "$file"
        fi
    done
else
    echo "No files to process in ${input_dir}" | tee -a "${LOG_FILE}"
fi

cp ${ARTWORK_DIR}/tmp/* ${ARTWORK_DIR} >> "${LOG_FILE}" 2>&1

echo | tee -a "${LOG_FILE}"
echo "Creating game assets..."  | tee -a "${LOG_FILE}"

# Read the file line by line
while IFS='|' read -r game_title game_id publisher disc_type file_name; do
  pp_game_id=$(echo "$game_id" | sed -E 's/_(...)\./-\1/;s/\.//')
  # Create a sub-folder named after the game_id
  game_dir="$ICONS_DIR/$game_id"
  mkdir -p "$game_dir" | tee -a "${LOG_FILE}"

   # Determine the launcher value for this specific game
  if [[ "$disc_type" == "POPS" ]]; then
    launcher_value="POPS"
    cp "${ASSETS_DIR}/POPStarter/"{1.png,2.png,bg.png,man.xml} "$game_dir"
  else
    launcher_value="$LAUNCHER"
  fi

  # Generate the info.sys file
  info_sys_filename="$game_dir/info.sys"
  cat > "$info_sys_filename" <<EOL
title = $game_title
title_id = $pp_game_id
title_sub_id = 0
release_date = 
developer_id = 
publisher_id = $publisher
note = 
content_web = 
image_topviewflag = 0
image_type = 0
image_count = 1
image_viewsec = 600
copyright_viewflag = 0
copyright_imgcount = 0
genre = 
parental_lock = 1
effective_date = 0
expire_date = 0
violence_flag = 0
content_type = 255
content_subtype = 0
EOL
  echo "Created info.sys: $info_sys_filename"  | tee -a "${LOG_FILE}"

  # Copy the matching .png file and rename it to jkt_001.png
  png_file="${TOOLKIT_PATH}/icons/art/${game_id}.png"
  if [[ -f "$png_file" ]]; then
    cp "$png_file" "$game_dir/jkt_001.png"
    echo "Artwork found for $game_title"  | tee -a "${LOG_FILE}"
  else
    if [[ "$disc_type" == "POPS" ]]; then
      cp "${TOOLKIT_PATH}/icons/art/ps1.png" "$game_dir/jkt_001.png"
      echo "Artwork not found for $game_title. Using default PS1 image" | tee -a "${LOG_FILE}"
      echo "$game_id $game_title" >> "${MISSING_ART}"
    else
      cp "${TOOLKIT_PATH}/icons/art/ps2.png" "$game_dir/jkt_001.png"
      echo "Artwork not found for $game_title. Using default PS2 image" | tee -a "${LOG_FILE}"
      echo "$game_id $game_title" >> "${MISSING_ART}"
    fi
  fi

done < "$ALL_GAMES"

echo | tee -a "${LOG_FILE}"
echo "All info.sys, and .png files have been created in their respective sub-folders." | tee -a "${LOG_FILE}"
echo | tee -a "${LOG_FILE}"
echo "Creating Launcher partitions and installing game assets..." | tee -a "${LOG_FILE}"

cd "${ASSETS_DIR}/BBNL"

i=0
# Reverse the lines of the file using tac and process each line
while IFS='|' read -r game_title game_id publisher disc_type file_name; do

    # Check the value of available
    if [ "$available" -lt 128 ]; then
        echo | tee -a "${LOG_FILE}"
        echo "Insufficient space for another partition." | tee -a "${LOG_FILE}"
        break
    fi

    # Format game id correctly for partition
    pp_game_id=$(echo "$game_id" | sed -E 's/_(...)\./-\1/;s/\.//')

    # Sanitize game_title by keeping only uppercase A-Z, 0-9, and underscores, and removing any trailing underscores
    sanitized_title=$(echo "$game_title" | tr 'a-z' 'A-Z' | sed 's/[^A-Z0-9]/_/g' | sed 's/^_//; s/_$//; s/__*/_/g')
    PARTITION_LABEL=$(printf "PP.%s.%s" "$pp_game_id" "$sanitized_title" | cut -c 1-32 | sed 's/_$//')

    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mkpart ${PARTITION_LABEL} 128M PFS\n"
    COMMANDS+="mount ${PARTITION_LABEL}\n"
    COMMANDS+="cd /\n"

    # Navigate into the sub-directory named after the gameid
    COMMANDS+="lcd '${ICONS_DIR}/${game_id}'\n"
    COMMANDS+="mkdir res\n"
    COMMANDS+="cd res\n"
    COMMANDS+="put info.sys\n"
    COMMANDS+="put jkt_001.png\n"

    # Check if man.xml exists
    if [ -f "${ICONS_DIR}/${game_id}/man.xml" ]; then
        COMMANDS+="put 1.png\n"
        COMMANDS+="put 2.png\n"
        COMMANDS+="put bg.png\n"
        COMMANDS+="put man.xml\n"
    fi

    COMMANDS+="umount\n"
    COMMANDS+="exit\n"

    echo "Creating $PARTITION_LABEL" | tee -a "${LOG_FILE}"
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1

    # Generate the BBNL cfg file
    # Determine the launcher value for this specific game
    if [[ "$disc_type" == "POPS" ]]; then
        launcher_value="POPS"
    else
        launcher_value="$LAUNCHER"
    fi
    bbnl_label="${PARTITION_LABEL:3}"
    bbnl_cfg="$ICONS_DIR/bbnl/$bbnl_label.cfg"
    cat > "$bbnl_cfg" <<EOL
file_name=$file_name
title_id=$game_id
disc_type=$disc_type
launcher=$launcher_value
EOL
    sudo "${HELPER_DIR}/HDL Dump.elf" modify_header "${DEVICE}" "${PARTITION_LABEL}" >> "${LOG_FILE}" 2>&1

    function_space
    ((i++))
done < <(tac "$ALL_GAMES")

cd "${TOOLKIT_PATH}"

# Set game launcher app
if [[ "$LAUNCHER" == "OPL" ]]; then
# Generate the BBNL cfg file for OPL
    cat > "$ICONS_DIR/bbnl/LAUNCHER.cfg" <<EOL
file_name=/bbnl/OPNPS2LD.ELF
title_id=OPENPS2LOAD
launcher=ELF
EOL
fi

if [[ "$LAUNCHER" == "NEUTRINO" ]]; then
# Generate the BBNL cfg file for NHDDL
    cat > "$ICONS_DIR/bbnl/LAUNCHER.cfg" <<EOL
file_name=/bbnl/nhddl.elf
title_id=NHDDL
launcher=ELF
arg=-mode=ata
EOL
fi

echo
echo "Preparing to sync PS1 games..." | tee -a "${LOG_FILE}"

sudo rm -f "$POPS_FOLDER"/*.[eE][lL][fF] >> "${LOG_FILE}" 2>&1

# Get the local POPS folder size in MB
POPS_SIZE=$(du -s --block-size=1M "$POPS_FOLDER" | awk '{print $1}')

echo | tee -a "${LOG_FILE}"
echo "Size of local POPS folder: ${POPS_SIZE} MB" | tee -a "${LOG_FILE}"

# Get the POPS partition size in MB
POPS_PARTITION=$(sudo "${HELPER_DIR}/HDL Dump.elf" toc ${DEVICE} | grep __.POPS | awk '{print $4}' | grep -oE '[0-9]+')

echo "Size of POPS partition: ${POPS_PARTITION} MB"| tee -a "${LOG_FILE}"

# Check if POPS_SIZE is greater than POPS_PARTITION - 128
THRESHOLD=$((POPS_PARTITION - 128))

if [ "$POPS_SIZE" -gt "$THRESHOLD" ]; then
    echo
    echo "Error: The local POPS folder is ${POPS_SIZE} MB, which exceeds the allowed limit of ${THRESHOLD} MB."| tee -a "${LOG_FILE}"
    echo "Remove some VCD files from the local POPS folder and try again."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Generate the local file list directly in a variable
local_files=$( { ls -1 "$POPS_FOLDER" | grep -Ei '\.VCD$' | sort; } 2>> "${LOG_FILE}" )

# Build the commands for PFS Shell
COMMANDS="device ${DEVICE}\n"
COMMANDS+="mount __.POPS\n"
COMMANDS+="ls\n"
COMMANDS+="umount\n"
COMMANDS+="exit"

# Get the PS1 file list directly from PFS Shell output, filtered and sorted
ps1_files=$(echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" 2>/dev/null | grep -iE "\.vcd$|\.elf$" | sort)

# Compute differences and store them in variables
files_only_in_local=$(comm -23 <(echo "$local_files") <(echo "$ps1_files"))
files_only_in_ps2=$(comm -13 <(echo "$local_files") <(echo "$ps1_files"))

# Only display "Files to delete:" if there are files to delete
if [ -n "$files_only_in_ps2" ]; then
    echo | tee -a "${LOG_FILE}"
    echo "Files to delete:" | tee -a "${LOG_FILE}"
    echo "$files_only_in_ps2" | tee -a "${LOG_FILE}"
else
    echo | tee -a "${LOG_FILE}"
    echo "No files to delete." | tee -a "${LOG_FILE}"
fi

# Only display "Files to copy:" if there are files to copy
if [ -n "$files_only_in_local" ]; then
    echo | tee -a "${LOG_FILE}"
    echo "Files to copy:" | tee -a "${LOG_FILE}"
    echo "$files_only_in_local" | tee -a "${LOG_FILE}"
else
    echo | tee -a "${LOG_FILE}"
    echo "No files to copy." | tee -a "${LOG_FILE}"
fi

# Syncing PS1 games
if [ -n "$files_only_in_ps2" ] || [ -n "$files_only_in_local" ]; then
    cd "$POPS_FOLDER" >> "${LOG_FILE}" 2>&1
    COMMANDS="device ${DEVICE}\n"
    COMMANDS+="mount __.POPS\n"

    # Add delete commands for files_only_in_ps2
    if [ -n "$files_only_in_ps2" ]; then
        while IFS= read -r file; do
            COMMANDS+="rm -f \"$file\"\n"
        done <<< "$files_only_in_ps2"
    fi

    # Add put commands for files_only_in_local
    if [ -n "$files_only_in_local" ]; then
        while IFS= read -r file; do
            COMMANDS+="put \"$file\"\n"
        done <<< "$files_only_in_local"
    fi

    COMMANDS+="umount\n"
    COMMANDS+="exit"

    # Execute the combined commands with PFS Shell
    echo | tee -a "${LOG_FILE}"
    echo "Syncing PS1 games to HDD..." | tee -a "${LOG_FILE}"
    echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1
    echo | tee -a "${LOG_FILE}"
    echo "PS1 games synced successfully." | tee -a "${LOG_FILE}"
    echo | tee -a "${LOG_FILE}"
else
    echo
    echo "PS1 games are already synced." | tee -a "${LOG_FILE}"
    echo | tee -a "${LOG_FILE}"
fi

# Check contents of __.POPS after sync
COMMANDS="device ${DEVICE}\n"
COMMANDS+="mount __.POPS\n"
COMMANDS+="ls\n"
COMMANDS+="umount\n"
COMMANDS+="exit"

echo -e "$COMMANDS" | sudo "${HELPER_DIR}/PFS Shell.elf" >> "${LOG_FILE}" 2>&1
echo >> "${LOG_FILE}"

# Syncing PS2 games
echo "Mounting OPL partition..." | tee -a "${LOG_FILE}"
mkdir -p "${TOOLKIT_PATH}"/OPL 2>> "${LOG_FILE}"

sudo mount ${DEVICE}3 "${TOOLKIT_PATH}"/OPL >> "${LOG_FILE}" 2>&1

# Handle possibility host system's `mount` is using Fuse
if [ $? -ne 0 ] && hash mount.exfat-fuse; then
    echo "Attempting to use exfat.fuse..." | tee -a "${LOG_FILE}"
    sudo mount.exfat-fuse ${DEVICE}3 "${TOOLKIT_PATH}"/OPL >> "${LOG_FILE}" 2>&1
fi

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to mount ${DEVICE}3" | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1;
fi

# Create necessary folders if they don't exist
for folder in APPS ART CFG CHT LNG THM VMC CD DVD bbnl; do
    dir="${TOOLKIT_PATH}/OPL/${folder}"
    [[ -d "$dir" ]] || sudo mkdir -p "$dir" || { 
        echo "Error: Failed to create $dir." | tee -a "${LOG_FILE}"
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    }
done

# Get the local games folder size in MB
PS2_SIZE=$(du -s --block-size=1M "${GAMES_PATH}" | awk '{print $1}')

echo | tee -a "${LOG_FILE}"
echo "Size of PS2 games: $PS2_SIZE MB" | tee -a "${LOG_FILE}"

OPL_PARTITION=$(df -m --output=size "${TOOLKIT_PATH}/OPL" | tail -n 1 | awk '{$1=$1};1')
echo "Size of OPL partition: ${OPL_PARTITION} MB" | tee -a "${LOG_FILE}"

# Check if PS2_SIZE is greater than OPL_PARTITION - 128
THRESHOLD=$((OPL_PARTITION - 128))

if [ "$PS2_SIZE" -gt "$THRESHOLD" ]; then
    echo
    echo "Error: The total size of local PS2 games is ${PS2_SIZE} MB, which exceeds the allowed limit of ${THRESHOLD} MB." | tee -a "${LOG_FILE}"
    echo "Remove some ISO/ZSO files from the local CD/DVD folders and try again."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo | tee -a "${LOG_FILE}"
echo "Checking for POPStarter update..." | tee -a "${LOG_FILE}"
sudo rsync -ut --progress "${POPSTARTER}" "${TOOLKIT_PATH}/OPL/bbnl/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to install POPStarter. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo "Checking for OPL update..." | tee -a "${LOG_FILE}"
sudo rsync -ut --progress "${ASSETS_DIR}/OPL/OPNPS2LD.ELF" "${TOOLKIT_PATH}/OPL/bbnl/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to install OPL. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo "Checking for NHDDL update..." | tee -a "${LOG_FILE}"
sudo rsync -ut --progress "${ASSETS_DIR}/NHDDL/nhddl.elf" "${TOOLKIT_PATH}/OPL/bbnl/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to install NHDDL. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo "Checking for Neutrino update..." | tee -a "${LOG_FILE}"
sudo rsync -rut --progress "${NEUTRINO_DIR}/" "${TOOLKIT_PATH}/OPL/neutrino/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to install Neutrino. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo | tee -a "${LOG_FILE}"
echo "Copying BBNL configs..." | tee -a "${LOG_FILE}"
sudo rm -f "${TOOLKIT_PATH}"/OPL/bbnl/*.cfg >> "${LOG_FILE}" 2>&1
sudo cp "${ICONS_DIR}"/bbnl/*.cfg "${TOOLKIT_PATH}/OPL/bbnl" >> "${LOG_FILE}" 2>&1

if [ $? -ne 0 ]; then
    echo
    echo
    echo "Error: Failed to copy BBNL config files. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

sudo mv "${TOOLKIT_PATH}/OPL/bbnl/conf_apps.cfg" "${TOOLKIT_PATH}/OPL" >> "${LOG_FILE}" 2>&1

echo | tee -a "${LOG_FILE}"
echo "Syncing PS2 games..." | tee -a "${LOG_FILE}"

# Sync PS2 CD games
sudo rsync -rL --progress --ignore-existing --delete --exclude=".*" "${GAMES_PATH}/CD/" "${TOOLKIT_PATH}/OPL/CD/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"
cd_status=$?

# Sync PS2 DVD games
sudo rsync -rL --progress --ignore-existing --delete --exclude=".*" "${GAMES_PATH}/DVD/" "${TOOLKIT_PATH}/OPL/DVD/" 2>>"${LOG_FILE}" | tee -a "${LOG_FILE}"
dvd_status=$?

# Check if either failed
if [ $cd_status -ne 0 ] || [ $dvd_status -ne 0 ]; then
    echo
    echo "Error: Failed to sync PS2 games. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
else
    echo | tee -a "${LOG_FILE}"
    echo "PS2 games successfully synced." | tee -a "${LOG_FILE}"
fi

echo | tee -a "${LOG_FILE}"
echo "Syncing Apps..." | tee -a "${LOG_FILE}"
echo
sudo rsync -rut --progress --delete --exclude=".*" --exclude="*.psu" --exclude="*.PSU" "${GAMES_PATH}/APPS/" "${TOOLKIT_PATH}/OPL/APPS/" >> "${LOG_FILE}" 2>&1
echo >> "${LOG_FILE}"
if [ $? -ne 0 ]; then
    echo
    echo "Error: Failed to sync Apps. See ${LOG_FILE} for details." | tee -a "${LOG_FILE}"
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Define the directories to check
dirs=(
    "${GAMES_PATH}/ART"
    "${GAMES_PATH}/CFG"
    "${GAMES_PATH}/CHT"
    "${GAMES_PATH}/LNG"
    "${GAMES_PATH}/THM"
    "${GAMES_PATH}/VMC"
)

# Flag to track if any files exist
files_exist=false

# Check each directory and copy files if not empty
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ] && [ -n "$(find "$dir" -type f ! -name '.*' -print -quit 2>/dev/null)" ]; then
        # Create the subdirectory in the destination path using the directory name
        folder_name=$(basename "$dir")
        dest_dir=""${TOOLKIT_PATH}"/OPL/$folder_name"
        
        # Copy non-hidden files to the corresponding destination subdirectory
        if [ "$folder_name" == "CFG" ] || [ "$folder_name" == "VMC" ]; then
            echo "Copying OPL $folder_name files..." | tee -a "${LOG_FILE}"
            find "$dir" -type f ! -name '.*' -exec sudo cp --update=none {} "$dest_dir" \; >> "${LOG_FILE}" 2>&1
        else
            if [ -n "$(find "$dir" -mindepth 1 ! -name '.*' -print -quit)" ]; then
            echo "Copying OPL $folder_name files..." | tee -a "${LOG_FILE}"
            sudo cp -r "$dir"/* "$dest_dir" >> "${LOG_FILE}" 2>&1
        fi
    fi
        files_exist=true
    fi
done

# Print message based on the check
if ! $files_exist; then
    echo "No OPL files to copy." | tee -a "${LOG_FILE}"
fi

echo >> "${LOG_FILE}"
echo "APPS on PS2 drive:" >> "${LOG_FILE}"
ls -1 "${TOOLKIT_PATH}/OPL/APPS/" >> "${LOG_FILE}" 2>&1
echo >> "${LOG_FILE}"
echo "PS2 Games on PS2 drive:" >> "${LOG_FILE}"
ls -1 "${TOOLKIT_PATH}/OPL/CD/" >> "${LOG_FILE}" 2>&1
ls -1 "${TOOLKIT_PATH}/OPL/DVD/" >> "${LOG_FILE}" 2>&1

echo | tee -a "${LOG_FILE}"
echo "Unmounting OPL partition..." | tee -a "${LOG_FILE}"
sync
sudo umount -l "${TOOLKIT_PATH}"/OPL

# Submit missing artwork to the PSBBN Art Database

cp $MISSING_ART $ARTWORK_DIR/tmp >> "${LOG_FILE}" 2>&1
cp $MISSING_APP_ART $ARTWORK_DIR/tmp >> "${LOG_FILE}" 2>&1

if [ "$(ls -A "${ARTWORK_DIR}/tmp")" ]; then
    echo | tee -a "${LOG_FILE}"
    echo "Contributing to the PSBBN art database..." | tee -a "${LOG_FILE}"
    cd $ARTWORK_DIR/tmp/
    zip -r $ARTWORK_DIR/tmp/art.zip *
    # Upload the file using transfer.sh
    upload_url=$(curl -F "reqtype=fileupload" -F "time=72h" -F "fileToUpload=@art.zip" https://litterbox.catbox.moe/resources/internals/api.php)

    if [[ "$upload_url" == https://* ]]; then
        echo "File uploaded successfully: $upload_url" | tee -a "${LOG_FILE}"

    # Send a POST request to Webhook.site with the uploaded file URL
    webhook_url="https://webhook.site/75a25957-c114-439e-93b0-1feab2e2d417"
    curl -X POST -H "Content-Type: application/json" \
        -d "{\"url\": \"$upload_url\"}" \
        "$webhook_url" >/dev/null 2>&1
    else
        echo "Error: Failed to upload the file." | tee -a "${LOG_FILE}"
    fi
else
    echo | tee -a "${LOG_FILE}"
    echo "No art work to contribute." | tee -a "${LOG_FILE}"
fi

echo | tee -a "${LOG_FILE}"
echo "Cleaning up..." | tee -a "${LOG_FILE}"
clean_up

sudo "${HELPER_DIR}/HDL Dump.elf" toc "$DEVICE" >> "${LOG_FILE}" 2>&1
echo | tee -a "${LOG_FILE}"
echo "Game installer script complete." | tee -a "${LOG_FILE}"
echo
read -n 1 -s -r -p "Press any key to exit..."
echo