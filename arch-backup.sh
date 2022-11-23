#bin/bash

rsync -av --delete --exclude '/home/rt/mnt' /home/rt/ /home/rt/mnt/red/Backups/arch-lt
