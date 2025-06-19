#!/bin/bash

# Script to create a custom Tiny Core Linux-based OS with BERKE0S.py
# Downloads BERKE0S.py from GitHub, converts it to .tcz, integrates it, and customizes the system

# Exit on any error
set -e

# Variables
GITHUB_URL="https://raw.githubusercontent.com/B3rk3-0ruc/BERKE0S-LINUX/main/BERKE0S.py"
TCZ_NAME="BERKE0S.tcz"
TCZ_DIR="/tmp/tce/optional"
WORK_DIR="/tmp/berke0s"
CONFIG_DIR="/home/tc/.berke0s"
STARTUP_SCRIPT="/opt/bootlocal.sh"
FILETOOL_LST="/opt/.filetool.lst"
BOOT_MSG="/boot/boot.msg"
ISOLINUX_CFG="/boot/isolinux/isolinux.cfg"
XSESSION="/home/tc/.Xsession"

# Step 1: Ensure required tools and dependencies are installed
echo "Installing required tools and dependencies..."
tce-load -wi squashfs-tools.tcz python3.8.tcz tk.tcz tcl.tcz python3.8-pip.tcz alsa.tcz bluez.tcz \
         e2fsprogs.tcz nano.tcz htop.tcz bash.tcz network-manager.tcz tar.tcz zip.tcz \
         dosfstools.tcz syslinux.tcz perl5.tcz mpv.tcz scrot.tcz libnotify.tcz alsa-utils.tcz \
         wireless-tools.tcz espeak.tcz util-linux.tcz

# Install Python dependencies
echo "Installing Python dependencies..."
sudo pip3 install psutil Pillow flask

# Step 2: Create working directory and download BERKE0S.py
echo "Creating working directory and downloading BERKE0S.py..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
wget -O BERKE0S.py "$GITHUB_URL"
chmod +x BERKE0S.py

# Step 3: Create directory structure for .tcz package
echo "Creating .tcz package structure..."
mkdir -p squashfs-root/usr/local/bin
mkdir -p squashfs-root/home/tc/.berke0s/{themes,plugins}
cp BERKE0S.py squashfs-root/usr/local/bin/
cd squashfs-root

# Step 4: Create .tcz package
echo "Creating $TCZ_NAME..."
mksquashfs . "$TCZ_DIR/$TCZ_NAME" -b 4k -noappend
cd ..
rm -rf squashfs-root

# Step 5: Add .tcz to onboot list for automatic loading
echo "Configuring $TCZ_NAME to load on boot..."
mkdir -p /tmp/tce
if ! grep -q "$TCZ_NAME" /tmp/tce/onboot.lst 2>/dev/null; then
    echo "$TCZ_NAME" | sudo tee -a /tmp/tce/onboot.lst
fi

# Step 6: Ensure BERKE0S.py runs on startup
echo "Configuring startup script..."
if ! grep -q "BERKE0S.py" "$STARTUP_SCRIPT"; then
    echo "# Run BERKE0S.py on startup" | sudo tee -a "$STARTUP_SCRIPT"
    echo "startx &" | sudo tee -a "$STARTUP_SCRIPT"
    echo "/usr/local/bin/BERKE0S.py &" | sudo tee -a "$STARTUP_SCRIPT"
fi
sudo chmod +x "$STARTUP_SCRIPT"

# Step 7: Configure X session to start automatically
echo "Configuring X session..."
if [ ! -f "$XSESSION" ]; then
    echo "exec /usr/local/bin/BERKE0S.py" | sudo tee "$XSESSION"
    sudo chmod +x "$XSESSION"
fi

# Step 8: Make startup script, .tcz, and configurations persistent
echo "Ensuring persistence..."
for path in usr/local/bin/BERKE0S.py tce/optional/"$TCZ_NAME" tce/onboot.lst home/tc/.berke0s; do
    if ! grep -q "$path" "$FILETOOL_LST"; then
        echo "$path" | sudo tee -a "$FILETOOL_LST"
    fi
done

# Step 9: Replace 'Tiny Core' with 'Berke0S' in system files
echo "Customizing system branding..."
if [ -f "$BOOT_MSG" ]; then
    sudo sed -i 's/Tiny Core/Berke0S/g' "$BOOT_MSG"
fi
if [ -f "$ISOLINUX_CFG" ]; then
    sudo sed -i 's/Tiny Core/Berke0S/g' "$ISOLINUX_CFG"
fi
find /etc -type f -exec sudo sed -i 's/Tiny Core/Berke0S/g' {} + 2>/dev/null || true

# Step 10: Save changes to make them persistent
echo "Saving changes..."
filetool.sh -b

# Step 11: Clean up
echo "Cleaning up..."
rm -rf "$WORK_DIR"

# Step 12: Inform user
echo "Installation complete! Reboot to apply changes."
echo "BERKE0S.py will run automatically on startup."
echo "The system branding has been updated to Berke0S."
