#!/bin/bash

#vars
USER=rt
HOME=/home/${USER}
PUBKEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLT0szO1EJOO2QtsyZTbeuCPb3lxuQvdYmrlusIhrM3g5MhdFCsvcF5Ya60TXs+CPsTPJ0XJJmc32qDMljCmk54= rt@rt-desktop"

#make user and dirs
useradd --create-home ${USER} --shell "/bin/bash"
usermod -aG sudo, docker ${USER}
mkdir ${HOME}/.ssh/

#ssh config
chmod 0700 "${HOME}/.ssh"
chmod 0600 "${HOME}/.ssh/authorized_keys"
chown -R ${USER}:${USER} ${HOME}/.ssh/
touch "${HOME}/.ssh/authorized_keys"
echo $PUBKEY >> ${HOME}/.ssh/authorized_keys && chown ${USER}:${USER} ${HOME}/.ssh/authorized_keys

#disable root login
echo "PermitRootLogin no" >> /etc/ssh/sshd_config 
echo "PermitEmptyPasswords no" /etc/ssh/sshd_config

# Message of the day 
sudo wget https://raw.githubusercontent.com/jwandrews99/Linux-Automation/master/misc/motd.sh
sudo mv motd.sh /etc/update-motd.d/05-info
sudo chmod +x /etc/update-motd.d/05-info

# Automatic downloads of security updates
sudo apt-get install -y unattended-upgrades
echo "Unattended-Upgrade::Allowed-Origins {
#   "${distro_id}:${distro_codename}-security";
#//  "${distro_id}:${distro_codename}-updates";
#//  "${distro_id}:${distro_codename}-proposed";
#//  "${distro_id}:${distro_codename}-backports";
#Unattended-Upgrade::Automatic-Reboot "true"; 
#}; " >> /etc/apt/apt.conf.d/50unattended-upgrades

#timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

#update and install
apt-get update -y && apt-get upgrade -y
sudo apt install -y \
	vim \
	git \
	curl \
	htop \
	unzip \
	python3-pip \
	python3-setuptools \
    build-essential \
    rclone \
    rsync \
    gpg \
    dnsutils \
    glances \

# tailscale install
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install tailscale

# fail2ban install
sudo apt-get install -y fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

echo "
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 4
" >> /etc/fail2ban/jail.local

#clean
apt autoremove -v 
apt clean -v 

echo " 
##################################
Do you want to reboot now? y / n
##################################
"
read $reboot
if [[ $reboot -eq "y" ]] || [[ $reboot -eq "yes" ]] ; then 
    reboot
else 
    echo "Reboot was not initiated"
fi

exit 0