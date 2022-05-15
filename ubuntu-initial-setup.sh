#!/bin/bash

#vars
USER=rt
HOME=/home/${USER}
PUBKEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLT0szO1EJOO2QtsyZTbeuCPb3lxuQvdYmrlusIhrM3g5MhdFCsvcF5Ya60TXs+CPsTPJ0XJJmc32qDMljCmk54= rt@rt-desktop"

#make user and dirs
useradd --create-home ${USER} --shell "/bin/bash"
usermod -aG sudo ${USER}
mkdir ${HOME}/.ssh/

#ssh config
chmod 0700 "${HOME}/.ssh"
chmod 0600 "${HOME}/.ssh/authorized_keys"
chown -R ${USER}:${USER} ${HOME}/.ssh/
touch "${HOME}/.ssh/authorized_keys"
echo $PUBKEY >> {${HOME}}/.ssh/authorized_keys && chown ${USER}:${USER} ${HOME}/.ssh/authorized_keys

#disable root login
# Disabling root login 
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

# Ffail2ban install
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

# docker install
echo "
######################################################################################################
Do you want to install docker? If so type y / If you dont want to install enter n
######################################################################################################
"
read $docker

if [[ $docker -eq "y" ]] || [[ $docker -eq "yes" ]]; then
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    sudo apt-get update -y
    apt-cache policy docker-ce
    sudo apt install docker-ce -y
    sudo apt-get install docker-compose -y 
    sudo usermod -aG docker ${USER}
    echo " 
    
        Installing Portainer on port 9000
    "

    sudo docker volume create portainer_data
    sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer

    echo "
#####################################################################################################    
                            Congrats Docker has been installed
######################################################################################################
"
    docker -v

else 
    echo "Docker was not installed"
 
fi

# wireguard install
echo "
######################################################################################################
Would you like to install a wireguard VPN Server? If so enter y / If you dont want to install enter n
######################################################################################################
"
read $vpn

if [[ $vpn -eq "y" ]] || [ $vpn -eq "yes" ]] ; then 
    wget https://raw.githubusercontent.com/l-n-s/wireguard-install/master/wireguard-install.sh -O wireguard-install.sh
    bash wireguard-install.sh

elif  [[ $vpn -eq "n" ]] || [ $vpn -eq "no" ]] ; then 
    echo "Wireguard wasnt installed"
else 
    echo "Error Install Aborted!"
    exit 1
fi

#clean
apt autoremove -v 
apt clean -v 

echo " Do you want to reboot now? y / n"
read $reboot

if [[ $reboot -eq "y" ]] || [[ $reboot -eq "yes" ]]; then
    sudo reboot
fi

exit 0