# PlayStation Broadband Navigator (PSBBN) Definitive English Patch

This is the definitive English patch for Sony's PlayStation Broadband Navigator (PSBBN) software for the PlayStation 2 (PS2) video game console.

You can find out more about the PSBBN software on Wikipedia [here](https://en.wikipedia.org/wiki/PlayStation_Broadband_Navigator).

## Patch Features
- A full English translation of the stock Japanese BB Navigator version 0.32
- All binaries, XML files, textures, and pictures have been translated*
- Compatible with any fat model PS2 console regardless of region**
- DNAS authorization checks bypassed to enable online connectivity
- Access working mirrors for the online game channels from Sony, Hudson, EA, Konami, Capcom, Namco, and KOEI. Hosted courtesy of vitas155 at psbbn.ru
- "Audio Player" feature re-added to the Music Channel from an earlier release of PSBBN, allowing compatibility with NetMD MiniDisc Recorders
- Associated manual pages and troubleshooting regarding the "Audio Player" feature translated and re-added to the user guide
- Japanese qwerty on-screen keyboard replaced with US English on-screen keyboard

Video demonstrating how PSBBN can be used in 2024. **Note**: Additional software and setup is required to achieve everything shown in this video. Click to watch:

[![IMAGE ALT TEXT HERE](https://github.com/user-attachments/assets/298c8c0b-5726-4485-840d-9d567498fd95)](https://www.youtube.com/watch?v=kR1MVcAkW5M)

---

## Version History

### v1.2 - 4th September 2024
- Fixed a bug on the Photo Channel that could potentially prevented the Digital Camera feature from being launched.
- Fixed formatting issues with a number of error messages where text was too long to fit on the screen.
- Various small adjustments and corrections to the translation throughout.

### v1.1.1 - 8th March 2024
**NEW**  
- X11 has been set to run in English. The restore, move, resize, minimize, and close buttons now show in English while using the NetFront web browser. When saving files, time stamps now also display in English formatting.

### v1.1 - 5th March 2024
**NEW**  
- The NetFront web browser is now in English. The browser can be accessed by going through the "Confirm/Change" network setting dialogs, then selecting "Change router settings".
- Atok user manual has been translated.

**BUG FIXES**  
- **General**: When a game disc was inserted while on the Top Menu, it would cause the console to freeze.  
- **Music Channel**: The number of times a track had been checked-out to a MiniDisc recorder was not displayed correctly.  
- A number of typos have been fixed.

### v1.0 - 21st September 2023
- Initial release.

---

## Installation Instructions

There are two ways to install this English patch:

1. [PS2 HDD RAW Image Install](#ps2-hdd-raw-image-install)
   - Use this method if you have access to a PC and a way to connect your PS2 HDD/SSD to your computer. This is the most straightforward option. All data on the HDD will be lost.

2. [Patch an existing PSBBN install](#patch-an-existing-psbbn-install)
   - Use this method if you already have an existing PSBBN install on your PlayStation 2 console. Also, follow these instructions to install future patch updates. No data will be lost.

---

### PS2 HDD RAW Image Install

#### What You Will Need
- Any fat model PS2 console
- An official Sony Network Adapter
- A compatible HDD or SSD (IDE or SATA with an adapter). The drive must be 120 GB or larger
- A way to connect the PS2 HDD to a PC
- 120 GB of free space on your PC to extract the files
- Disk imaging software

#### Installation Procedure
1. Download [PSBBN_English_Patched_v1.x.x_Image.7z](https://archive.org/download/playstation-broadband-navigator-psbbn-definitive-english-patch-v1.0/PSBBN_English_Patched_v1.2_Image.7z) and uncompress it.
`PSBBN_English_Patched_v1.x.x_HDD_RAW.img` is a raw PS2 disk image of the Japanese PlayStation BB Navigator Version 0.32 with the PlayStation Broadband Navigator (PSBBN) Definitive English Patch pre-installed.
2. To write this image to your PS2 HDD, you need disk imaging software. For Windows, I recommend using HDD Raw Copy ver. 1.10 portable. You can download it [here](https://hddguru.com/software/HDD-Raw-Copy-Tool/).

---

### Patch an existing PSBBN install

#### What You Will Need
- Any fat model PS2 console**
- An official Sony Network Adapter
- A compatible HDD or SSD (IDE or SATA with an adapter)
- An existing install of PSBBN software 0.32 on your PS2 console
- A Free McBoot Memory Card
- A USB flash drive formatted as FAT32
- A USB keyboard

#### Installing the English Patch
1. Install the PSBBN software on your PS2 console if you haven't done so already. Either via a disk image or manually, see the section [Installing the Japanese PSBBN software](#installing-the-japanese-psbbn-software) below for details on a manual install.
2. Download [PSBBN_English_Patch_Installer_v1.x.x.zip](https://archive.org/download/playstation-broadband-navigator-psbbn-definitive-english-patch-v1.0/PSBBN_English_Patch_Installer_v1.2.zip) and unzip it on your PC.
3. Copy the files `kloader3.0.elf`, `config.txt`, `xrvmlinux`, `xrinitfs_install.gz`, and `PSBBN_English.tar.gz` to the root of a FAT32 formatted USB flash drive.
4. Connect the USB flash drive and a USB keyboard to the USB ports on the front of your PS2 console.
5. Turn the PS2 console on with your Free McBoot Memory Card inserted and load wLaunchELF.
6. Load `kloader3.0.elf` from the USB flash drive.
7. Eventually, you will be presented with a login prompt:  
     Type `root` and press enter.  
     Type `install` and press enter.
8. When you see the text `INIT: no more processes left in this runlevel`, hold the standby button down until the console powers off.

Remove your Free McBoot Memory Card. Power the console on and enjoy PSBBN in full English!

---

## Installing the Japanese PSBBN software

There are a number of ways this can be achieved. On a Japanese PlayStation 2 console with an **official PSBBN installation disc**, or with **Sony Utility Discs Compilation 3**.

To install via **Sony Utility Discs Compilation 3** you will need a way to boot backup discs on your console, be that a mod chip or a swap disc. If your are lucky enough to have a **SCPH-500xx** series console you can use the **MechaPwn** softmod.

### Installing with Sony Utility Discs Compilation 3

**Preparations**
1. Download the **Sony Utility Discs Compilation 3** ISO from the Internet Archive [here](https://archive.org/details/sony-utility-disc-compilation-v3).
2. **SCPH-500xx consoles only**: Patch the ISO with the [Master Disc Patcher](https://www.psx-place.com/threads/playstation-2-master-disc-patcher-for-mechapwn.36547/).
3. Burn this ISO to a writable DVD. I recommend using [ImgBurn](https://www.imgburn.com).
4. **SCPH-500xx consoles only**: MechaPwn your PS2 console with the latest release candidate, currently [MechaPwn 3.0 Release Candidate 4 (RC4)](https://github.com/MechaResearch/MechaPwn/releases/tag/3.00-rc4). It is important that you use a version of MechaPwn that does not change the **Model Name** of your console or it will break compatibility with the Kloader app, we use later in this guide. Currently the latest stable version is not compatible. More details about exactly what MechaPwn does and how to use it can be found [here](https://github.com/MechaResearch/MechaPwn).
5. Format the PS2 HDD. In wLaunchELF press the `circle` button for **FileBrowser**, then select **MISC > HddManager**. Press `R1` to open the menu and select **Format**. When done, press `triangle` to exit.
6. Launch the **Sony Utility Discs Compilation 3** DVD on your console. **SCPH-500xx consoles only:** Insert your newly burnt **Sony Utility Discs Compilation 3** DVD into the DVD drive on your PS2 console. On the first screen of wLaunchELF, press the `circle` button for **FileBrowser**, then select **MISC > PS2Disc**. The DVD will launch. On all other model consoles, launch the **Sony Utility Discs Compilation 3** DVD any way you can (e.g. Mod chip/Swap disc).
7. After the disc loads, select **HDD Utility Discs > PlayStation BB Navigator Version 0.32** from the menu to begin the installation.

**Installation**  
There's an excellent guide [here](https://bungiefan.tripod.com/psbbninstall_01.html) that talks you through the Japanese install. Because we have already formatted the hard drive, during the install you will be presented with a [different screen](https://bungiefan.tripod.com/psbbninstall_02.html). It's important that you select the 3rd install option. This will install PSBBN without re-formatting the HDD. When the install is complete you will be instructed to remove the DVD, do so but also remove your Free McBoot Memory Card, before pressing the `circle` button.

**Network Settings**  
You will be asked to enter your network settings. Make sure your Ethernet cable is connected. Everything is still in Japanese, but it's relatively straightforward:
1. Press the `circle` button on the first screen.
2. On the next screen, select the **bottom** option, "Do not use PPPoE" and press `circle`.
3. On the next screen, select the **top** option, “Auto" for you IP address and press `circle`.
4. On the next screen, select the **top** option, “Auto” for DNS settings and press `circle`.
5. Press `right` on the d-pad to proceed to the next screen.
6. Select the **bottom** option, "Do not change router settings" and press `circle`.
7. Finally, press `circle` again to confirm your settings.

For your efforts you will be given a DNAS error. This is to be expected. We'll fix that next. Press `X` and feel free to explore your fresh install of the Japanese PSBBN.

**Disable DNAS Authentication**  
1. Turn off the console and put your Free McBoot Memory Card back into a memory card slot.  
2. Turn the console on and load wLaunchELF.  
3. Go to **FileBrowser**. Navigate to `hdd0:/__contents/bn.conf/` and delete the file `default_isp.dat`. This will disable the DNAS checks.

**Please Note**
Before installing the English patch, you **must** power off your console to standby mode by holding the reset button. Failure to do so will cause issues with Kloader.

---

## Notes
- I would highly recommend using a **"Kaico IDE to SATA Upgrade Kit"** and a SATA SSD such as the **Kingston A400**. The improved random access speed over a HDD really makes a big difference to the responsiveness of the PSBBN interface.
- Use OPL-Launcher to launch PS2 games from the Game Channel. More details can be found [here](https://github.com/ps2homebrew/OPL-Launcher).

---

## Known Issues/Limitations of PSBBN
- Lacks support for large HDDs so drives larger than 130 GB cannot be taken full advantage of. PSBBN can only see the first 130,999 MB of data on your HDD/SSD (as reported by wLaunchELF). If there is 131,000 MB or more on your HDD/SSD, PSBBN will fail to launch. Delete data so there is less than 131,000 MB used, and PSBBN will launch again. In that space, I've managed to install 40 PS2 games in the ZSO format, 9 PS1 games, all bootable from the Game Channel, plus 3 homebrew apps, and Linux. Be extra careful if you have installed via the [PS2 HDD RAW Image](#ps2-hdd-raw-image-install) on a drive larger than 120 GB, going over 130,999 MB will corrupt the drive.
- Only supports dates up to the end of 2030.
- Bug with Game Manuals randomly crashing when loading pages. Manuals only work reliably on the first 5 games installed.
- Default on-screen keyboard is Japanese. US English on-screen keyboard has been added, but you have to press SELECT a number of times to access it. I've noticed a bug where the spacebar key does not function on the US English on-screen keyboard. A space can be entered by pressing the triangle button on the controller instead. I could revert back to the Japanese qwerty keyboard in the future, but I think the benefits of the US keyboard outweigh this negative.

---

\* Instances in feega where some Japanese text could not be translated because it is hard coded, most likely in an encrypted file. Atok software has not been translated. You might have to manually change the title of your "Favorite" folders if they were created before running this patch.  
\** Patching an existing PSBBN install is not supported on early model PS2 consoles with an external HDD due to incompatibility with Kloader. The PS2 HDD RAW Image should work with all fat model PS2 consoles.
