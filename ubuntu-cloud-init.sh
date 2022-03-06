#!/bin/sh

# new user
USERNAME=rt

# copy root keys
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
usermod -aG docker rt

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
fi

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

# mkdir 
mkdir /home/rt/working
chown rt:rt /home/rt/working

# set timezone
timedatectl set-timezone America/New_York

# updates
apt-get update -y && apt-get upgrade -y

# install utils
sudo apt-get install wget curl git gpg vim unzip dnsutils htop python3-pip python3-setuptools build-essential glances rclone rsync -y 

#install tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install tailscale -y