#!/usr/bin/env sh
# A script to print verbose information about a websites SSL cert
if [ "$1" == "" ]; then
	printf "Usage: $0 domainname.com\n"
	exit 1
fi
echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text

