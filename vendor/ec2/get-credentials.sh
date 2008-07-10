#!/bin/bash

# Fetch any credentials presented at launch time and add them to
# root's public keys

PUB_KEY_URI=http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key
PUB_KEY_FROM_HTTP=/m/tmp/openssh_id.pub
ROOT_AUTHORIZED_KEYS=/root/.ssh/authorized_keys

# We need somewhere to put the keys.
if [ ! -d /root/.ssh ] ; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
fi

# Fetch credentials...
curl --retry 3 --retry-delay 0 --silent --fail -o $PUB_KEY_FROM_HTTP $PUB_KEY_URI
if [ $? -eq 0 -a -e $PUB_KEY_FROM_HTTP ] ; then
    if ! grep -q -f $PUB_KEY_FROM_HTTP $ROOT_AUTHORIZED_KEYS
    then
            cat $PUB_KEY_FROM_HTTP >> $ROOT_AUTHORIZED_KEYS
	    echo "New key added to authrozied keys file from parameters"|logger -t "ec2"
    fi
    chmod 600 $ROOT_AUTHORIZED_KEYS
    rm -f $PUB_KEY_FROM_HTTP

fi
