#!/bin/bash
for ip in `cat ./servers`; do
    ssh-copy-id -i ~/.ssh/id_rsa.pub $ip
done

