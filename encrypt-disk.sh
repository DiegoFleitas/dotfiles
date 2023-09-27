#!/bin/bash
# set -x  # This will bash print each command before executing it.

# Reminder for backup
echo "Ensure you've backed up all your data before proceeding!"
read -p "Press enter to continue if you've backed up, or Ctrl+C to exit." dummyVar # dummyVar placeholder to capture input

# Step 1: Install Encryption Packages
sudo apt update
sudo apt install ecryptfs-utils cryptsetup -y

# Step 2: Create Another User and Assign Sudo Privileges
sudo adduser tempuser
sudo usermod -aG sudo tempuser

echo "Log out and login as 'tempuser', then run the next part of the script."
# The script ends here and you'll run the next parts after logging in as 'tempuser'
# Pause script here, you'd manually log out and then continue after logging back in.

# Step 3: Check & Encrypt the Home Directory
# Note: Replace <user> with your actual username. Be aware of typos (psst Ecrypt not eNcrypt...)
# $ sudo ls -l ~<user>
# $ sudo ecryptfs-migrate-home -u <user>

# Step 4: Confirm Encryption and Record Passphrase
# Note: Log out from the privileged user account and log back in (DO NOT REBOOT!) to your regular user account.

# Confirm you can read/write files in your home directory. 
# $ echo "Hi" > test.txt & cat test.txt
# $ rm test.txt

# If the above command succeeds, it means you've successfully encrypted and can decrypt your home directory.

# Record your passphrase. 
# First, try using the pop-up GUI, if available.
# If you're running this remotely or in a terminal-only mode:
# $ ecryptfs-unwrap-passphrase

# Step 5: Encrypt the Swap Space
# Check if you have a swap space:
# $ swapon -s
# If you do, encrypt it:
# $ sudo ecryptfs-setup-swap

# Step 6: Cleanup
# Remove the temporary encryption user:
# $ sudo deluser --remove-home tempuser
# Remove the backup home folder that was created during migration:
# Note: Replace <user> with your actual username for the below command
# $ sudo rm -Rf /home/<user>.MTL8*
