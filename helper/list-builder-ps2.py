import sys
import math
import os.path
import subprocess
import unicodedata
from natsort import natsorted

done = "Error: No games found."
total = 0
count = 0
pattern_1 = [b'\x01', b'\x0D']
pattern_2 = [b'\x3B', b'\x31']

# Function to count game files in the given folder
def count_files(folder, extensions):
    global total
    for image in os.listdir(game_path + folder):
        if any(image.lower().endswith(ext) for ext in extensions):
            total += 1

# Function to process game files in the given folder
def process_files(folder, extensions):
    global total
    global count
    global done

    gameid_file_path = "./helper/TitlesDB_PS2_English.csv"

    # Read TitlesDB_PS2_English.csv and create a dictionary of title IDs to game names
    game_names = {}
    if os.path.isfile(gameid_file_path):
        with open(gameid_file_path, 'r') as gameid_file:
            for line in gameid_file:
                parts = line.strip().split('|')  # Split title ID and game name
                if len(parts) == 3:
                    game_names[parts[0]] = (parts[1], parts[2])

    # Prepare a list to hold all game list entries
    game_list_entries = []

    for image in os.listdir(game_path + folder):
        if any(image.lower().endswith(ext) for ext in extensions):
            print(math.floor((count * 100) / total), '% complete')
            print('Processing', image)
            index = 0
            string = ""

            original_image = image  # Store the original filename (e.g., `.zso` or `.iso`)
            converted_iso = False

            
            # Check the filename condition for all files
            file_name_without_ext = os.path.splitext(image)[0]
            if len(file_name_without_ext) >= 9 and file_name_without_ext[4] == '_' and file_name_without_ext[8] == '.':
                # Filename meets the condition, directly set the game ID
                string = file_name_without_ext[:11]
                print(f"Filename meets condition. Game ID set directly from filename: {string}")

             # If the file has a .zso extension and no ID was set, convert to .iso
            if image.lower().endswith('.zso') and not string:
                zso_path = os.path.join(game_path + folder, image)
                iso_path = os.path.join(game_path + folder, os.path.splitext(image)[0] + '.iso')

                print(f"Converting {image} from .zso to .iso...")
                venv_activate = os.path.join('venv', 'bin', 'activate')
                command = f"source {venv_activate} && python3 ./helper/ziso.py -c 0 '{zso_path}' '{iso_path}'"
                subprocess.run(command, shell=True, check=True, executable='/bin/bash')

                # Update image to the new .iso path for processing
                image = os.path.basename(iso_path)
                converted_iso = True  # Mark the .iso file as being converted from .zso

            # Extract the game ID from the file content if not set by the filename
            if not string:  # Only process if the game ID is not set from the filename
                with open(game_path + folder + "/" + image, "rb") as file:
                    while (byte := file.read(1)):
                        if len(string) < 4:
                            if index == 2:
                                string += byte.decode('utf-8', errors='ignore')
                            elif byte == pattern_1[index]:
                                index += 1
                            else:
                                string = ""
                                index = 0
                        elif len(string) == 4:
                            index = 0
                            if byte == b'\x5F':
                                string += byte.decode('utf-8', errors='ignore')
                            else:
                                string = ""
                        elif len(string) < 8:
                            string += byte.decode('utf-8', errors='ignore')
                        elif len(string) == 8:
                            if byte == b'\x2E':
                                string += byte.decode('utf-8', errors='ignore')
                            else:
                                string = ""
                        elif len(string) < 11:
                            string += byte.decode('utf-8', errors='ignore')
                        elif len(string) == 11:
                            if byte == pattern_2[index]:
                                index += 1
                                if index == 2:
                                    break
                            else:
                                string = ""
                                index = 0

            count += 1

            # Fallback if no title ID is found
            if len(string) != 11:
                string = os.path.splitext(original_image)[0][:11]
                print(f'No title ID found. Defaulting to first 11 chars of filename: {string}')

            # Rename the original `.zso` file to begin with the `gameid`
            if converted_iso:
                new_filename = f"{string}.{original_image}"
                new_zso_path = os.path.join(game_path + folder, new_filename)
                os.rename(zso_path, new_zso_path)
                print(f"Renamed {original_image} to {new_filename}")
                original_image = new_filename  # Update the original image reference

            # Determine game name and publisher
            entry = game_names.get(string)
            if entry:
                game_name, publisher = entry
            else:
                game_name = os.path.splitext(original_image)[0]
                publisher = ""

            # Format entry with game name, game ID, publisher, and updated original image info
            folder_image = f"{folder.replace('/', '', 1)}|{original_image}"
            game_list_entry = f"{game_name}|{string}|{publisher}|{folder_image}"
            game_list_entries.append(game_list_entry)

            # If the file was converted from .zso to .iso, delete the .iso file
            if converted_iso:
                os.remove(game_path + folder + "/" + image)
                print(f"Deleted the temporary ISO file: {image}")

    # Write all entries to the ps2.list file
    if game_list_entries:
        with open(games_list_path, "a") as output:
            for entry in game_list_entries:
                output.write(f"{entry}\n")

    done = "Done!"

# Function to normalize text by removing diacritical marks and converting to ASCII
def normalize_text(text):
    """
    Normalize text by removing diacritical marks and converting to ASCII.
    """
    return ''.join(
        c for c in unicodedata.normalize('NFD', text)
        if unicodedata.category(c) != 'Mn'
    )

# Main function to sort the games list
def sort_games_list():

    # Read the ps2.list into a list of lines
    with open(games_list_path, 'r') as file:
        lines = file.readlines()

    # Sort the lines by the first field dynamically
    def sort_key(line):
        # Split the line into fields
        fields = line.strip().split('|')

        # Extract the game title (first field) and game_id (second field, if present)
        first_field = fields[0].strip()
        game_id = fields[1].strip() if len(fields) > 1 else ""

        # Special condition for 'Jak and Daxter: The Precursor Legacy'
        if first_field.lower() == "jak and daxter: the precursor legacy":
            return ("jak", game_id)
        
        # Special condition for 'Ratchet: Deadlocked'
        if first_field.lower() == "ratchet: deadlocked":
            return ("ratchet & clank", game_id)
        
        # Special condition for 'Ratchet: Deadlocked'
        if first_field.lower() == "secret agent clank":
            return ("ratchet & clank", game_id)
        
        # Special condition for 'Sly Cooper and the Thievius Raccoonus'
        if first_field.lower().startswith("sly cooper and the thievius raccoonus"):
            return ("sly", game_id)

        # Special condition for 'Zone of the Enders: The 2nd Runner'
        if first_field.lower().startswith("zone of the enders: the 2nd runner"):
            return ("zone of the enders 2", game_id)
        
        # Special condition for 'Grand Theft Auto III'
        if first_field.lower().startswith("grand theft auto iii"):
            return ("grand theft auto", game_id)
        
        # Special condition for 'The Document of Metal Gear Solid 2'
        if first_field.lower().startswith("the document of metal gear solid 2"):
            return ("metal gear solid 2", game_id)
        
        # Special condition for 'Forbidden Siren'
        if first_field.lower().startswith("forbidden siren 2"):
            return ("siren 2", game_id)
        
        # Special condition for 'We Love Katamari'
        if first_field.lower().startswith("we love katamari"):
            return ("katamari damacy 2", game_id)
        
        # Check for colon and truncate at the first colon, if exists
        if ':' in first_field:
            first_field = first_field.split(':')[0].strip()

        # Remove leading "The" or "the" for sorting purposes
        if first_field.lower().startswith('the '):
            first_field = first_field[4:].strip()

        # Normalize the title
        normalized_title = normalize_text(first_field)

        # Remove special characters
        normalized_title = ''.join(c for c in normalized_title if c.isalnum() or c.isspace())

        # Check for special cases like Roman numeral endings
        replacements = {
            ' I': ' 1',
            ' II': ' 2',
            ' III': ' 3',
            ' IV': ' 4',
            ' V': ' 5',
            ' VI': ' 6',
            ' VII': ' 7',
            ' VIII': ' 8',
            ' IX': ' 9',
            ' X': ' 10',
            ' XI': ' 11',
            ' XII': ' 12',
            ' XIII': ' 13',
            ' XIV': ' 14',
            ' XV': ' 15',
            ' XVI': ' 16',
            ' XVII': ' 17',
            ' XVIII': ' 18',
            ' XIX': ' 19',
            ' XX': ' 20'
        }
        for roman, digit in replacements.items():
            if normalized_title.endswith(roman):
                normalized_title = normalized_title.replace(roman, digit)
                break

        final_key = normalized_title.lower()
        return (final_key, game_id)

    # Sort the lines by the dynamic key using natsorted
    sorted_lines = natsorted(lines, key=sort_key)

    # Write the sorted lines back to the specified games list path
    with open(games_list_path, 'w') as file:
        file.writelines(sorted_lines)

def main(arg1, arg2):
    if arg1 and arg2:
        global game_path
        global games_list_path
        game_path = arg1
        games_list_path = arg2

        # Remove any existing game list file
        if os.path.isfile(games_list_path):
            os.remove(games_list_path)

    # Count and process files in the DVD and CD folders
    for folder, extensions in [('/DVD', ['.iso', '.zso']), ('/CD', ['.iso', '.zso'])]:
        if os.path.isdir(game_path + folder):
            count_files(folder, extensions)
        else:
            print(f'{folder} not found at ' + game_path)
            sys.exit(1)

    # Check if no games were found
    if total == 0:
        print("No PS2 games found in the CD or DVD folder.")
        sys.exit(1)

    # Process the files now that we know there are games
    for folder, extensions in [('/DVD', ['.iso', '.zso']), ('/CD', ['.iso', '.zso'])]:
        if os.path.isdir(game_path + folder):
            process_files(folder, extensions)

    # Sort the games list after processing
    sort_games_list()

    print(done)
    print('')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python3 list_builder-ps1.py <path/to/games> <path/to/ps2.list>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])