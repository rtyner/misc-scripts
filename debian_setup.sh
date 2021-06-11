#!/bin/bash

#initial updates and cleanup
apt update && sudo apt upgrade -v -y
apt autoremove -v 
apt clean -v 

#rename computer
echo enter new hostname
read new_hostname
hostname $new_hostname

#disable root login with pw
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

function setupTimezone() {
    echo -ne "Enter the timezone for the server (Default is 'Asia/Singapore'):\n" >&3
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="Asia/Singapore"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3
}
