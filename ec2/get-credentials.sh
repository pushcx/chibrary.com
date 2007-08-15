#!/bin/bash

# Retreive the credentials from relevant sources.

# Fetch any credentials presented at launch time and add them to
# root's public keys

PUB_KEY_URI=http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key
PUB_KEY_FROM_HTTP=/tmp/openssh_id.pub
PUB_KEY_FROM_EPHEMERAL=/mnt/openssh_id.pub
ROOT_AUTHORIZED_KEYS=/root/.ssh/authorized_keys



# We need somewhere to put the keys.
if [ ! -d /root/.ssh ] ; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
fi

# Fetch credentials...

# First try http
curl --retry 3 --retry-delay 0 --silent --fail -o $PUB_KEY_FROM_HTTP $PUB_KEY_URI
if [ $? -eq 0 -a -e $PUB_KEY_FROM_HTTP ] ; then
    if ! grep -q -f $PUB_KEY_FROM_HTTP $ROOT_AUTHORIZED_KEYS
    then
            cat $PUB_KEY_FROM_HTTP >> $ROOT_AUTHORIZED_KEYS
	    echo "New key added to authrozied keys file from parameters"|logger -t "ec2"
    fi
    chmod 600 $ROOT_AUTHORIZED_KEYS
    rm -f $PUB_KEY_FROM_HTTP

elif [ -e $PUB_KEY_FROM_EPHEMERAL ] ; then
    # Try back to ephemeral store if http failed.
    # NOTE: This usage is deprecated and will be removed in the future
    if ! grep -q -f $PUB_KEY_FROM_EPHEMERAL $ROOT_AUTHORIZED_KEYS
    then 
            cat $PUB_KEY_FROM_EPHEMERAL >> $ROOT_AUTHORIZED_KEYS
	    echo "New key added to authrozied keys file from ephemeral store"|logger -t "ec2"

    fi
    chmod 600 $ROOT_AUTHORIZED_KEYS
    chmod 600 $PUB_KEY_FROM_EPHEMERAL

fi

if [ -e /mnt/openssh_id.pub ] ; then
	if ! grep -q -f /mnt/openssh_id.pub /root/.ssh/authorized_keys
	then
	        cat /mnt/openssh_id.pub >> /root/.ssh/authorized_keys
		echo "New key added to authrozied keys file from ephemeral store"|logger -t "ec2"

	fi
        chmod 600 /root/.ssh/authorized_keys
fi
