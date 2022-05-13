#!/bin/bash
set -euo pipefail

# new user
USERNAME=rt

# Additional public keys to add to the new sudo user
 OTHER_PUBLIC_KEYS_TO_ADD=(
     "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLT0szO1EJOO2QtsyZTbeuCPb3lxuQvdYmrlusIhrM3g5MhdFCsvcF5Ya60TXs+CPsTPJ0XJJmc32qDMljCmk54= rt@rt-desktop"
     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvdVLSsqX3703QiOxyjwhLDgy3JCdnzBB629mEa9fPeG1zgPtsf8WBH+PnkJIJkhvZcySu67d90nENH4adjsHOkSzW7U3qseTpp7kpqC7k2eO8g66zbhIvyHY8gJvSeqFyOAMbB9rS/BXg/9nawUeGCNntoB8ES5RABi+XOWsvAdp0Z04nfJ5vh3YvnH2NfKIzD2MPVVRtCP3YJ7VImefm5NSSYCQ5KO0YzxRRc+WE3vRMe6PVy/agUF0ngoa7BDMBz/pZF/FrG2fsDPVUvWhlfiO8cHRilypL8rfIT5zx7LWsQKXe/K4C5b+/8WQOsKFNmAI8061S1lDl3lY+6aO4rPX9F7A46rJ6Nea88ZT2aiTJDE1TTlPlSj8M94O7To3yEVY+BiExC+bZqe7El4ThlDxAFJQNUhryhqhEItGqggmz769ppSO20oeo5geq7eKV5wgGeBdDl62mzl88b3kp3RP8jyzjoZYIxmK8s4KgIx017Y7KI1tzFHFFOBi9yAHQGBLq4k9oA41t0dSKwjki29PU53zPFIPu2v6ZcpeywjC3KG/9Ei6hUy7j3tfCnt03DJ1u2/rK8PmvFzKfBA8zM5AMxmjNFNb4SUnMUEuJbznfnji/qMJdgficvLRcBIfwhYhT4ybZy76VAP3TW7UMknqwhNFYwiMtCtpZsPHBDQ== rt@LAK-IT-LT03"
     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxcbuhrJEz9BjgXYZFr0llTvkZioGMpDy9FvjY2cT7mfxZvd/u4VqoDHjjNn7HTUWmJr+1o/1fmAdWWmIXjShX8T1S92NXcqiqKdrzwl/7YopXamCwEeQFrh17RjmzSBZ7vQ67GKGVyR8dwDOJOHsv5KZnW9w3WkTdgk9uspgX7yn0/Q9pRAvujyLY1uw0GQtusIAsbQKk3bU8ErlpoVi1Zj2LPqOsJzd/sZ9X1o9cemmrXDzLYvjzWZvjNp4fhmb2NKRQSCzypOempNbIYZ50FiYcGFUnIbqUMBJSeMhhZFfnIjK9HBEsqiB5NVHFEEHck63M0YThMh5WjRm5HfUJvUdm/bGqTwgXpuY5tAs+xbEdsfrLaFpCNRr/jkXVppsZid/ls9iBnYt+nH+uBBQ9Fx6g9T7PzxdwdX0CVqqVJs2M+JwSBXKexrh6Tz/3Td2yU8rz6VvSYezaCsaTU9r9EpoNtW11UJHYkWQ2g9U2JarSZh/ShroAJWvOTEkBOFk= rt@rts-MacBook-Pro.local"
 )
OTHER_PUBLIC_KEYS_TO_ADD=(
)

# add user to sudo
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
usermod -a -G docker rt

# check root pw
encrypted_root_pw="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

if [ "${encrypted_root_pw}" != "*" ]; then
    # Transfer auto-generated root password to user if present
    # and lock the root account to password-based access
    echo "${USERNAME}:${encrypted_root_pw}" | chpasswd --encrypted
    passwd --lock root
else
    # Delete invalid password for user if using keys so that a new password
    # can be set without providing a previous value
    passwd --delete "${USERNAME}"
fi

# Expire the sudo user's password immediately to force a change
chage --lastday 0 "${USERNAME}"

# Create SSH directory for sudo user
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
fi

# Add additional provided public keys
for pub_key in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
    echo "${pub_key}" >> "${home_directory}/.ssh/authorized_keys"
done

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

# Add exception for SSH and then enable UFW firewall
ufw allow OpenSSH
ufw --force enable

# mkdir 
mkdir /home/rt/working
chown rt:rt /home/rt/working

# set timezone
timedatectl set-timezone America/New_York

# updates
apt-get update -y && apt-get upgrade -y

# install utils
sudo apt-get install wget curl git gpg vim zsh unzip dnsutils -y 

# zsh
#sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#curl https://raw.githubusercontent.com/rtyner/dotfiles/master/zsh/.zshrc >> /home/rt/.zshrc
#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
#echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
#chsh -s $(which zsh)

# install tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install tailscale
