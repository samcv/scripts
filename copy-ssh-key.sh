#!/usr/bin/env bash
# Copys your SSH key to the specified user's authorized keys
# This allows you to login using root/other user that has sudo
user=$1
server=$2
if [ "$user" == "" ] || [ "$server" = "" ]; then
	printf "Usage: $0 username root@myserver.com\n"
	printf "Copys your SSH key to the specified user's authorized keys\n"
	exit 1;
fi
cat ~/.ssh/id_rsa.pub | \
	ssh "$server" \
	"sudo mkdir -p /home/$user/.ssh; sudo tee -a /home/$user/.ssh/authorized_keys; sudo chown -R $user:$user /home/$user/.ssh"
