#!/bin/bash

set -e

VAGRANT_INSECURE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

VAGRANT_IP="192.168.33.10"
VAGRANT_PORT=22
EXISTS_PUB=~/.ssh/id_rsa.pub

HELP="\n
-e PUB_KEY             - Key public file\n
-p PORT                - Vagrant port\n
-i VAGRANT_IP          - Vagrant destination IP\n
-v                     - Verbose mode\n
-h                     - Show this message\n
"


function about {
    echo -e $HELP
    exit 0
}


function verbose {
    set -v
}

function setip {
 if [ -z `sed -r '/^([[:digit:]]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})(:[1-9][0-9]{0,5})?$/d' <<<$1` ]; then
    VAGRANT_IP=$1
 else
    echo "No es una ip valida $1"
    exit 1
 fi
}

function setport {
  if [ -z `sed -r '/^[1-9][0-9]{0,5}?$/d' <<<$1` ]; then
    VAGRANT_PORT=$1
  else
    echo "No es un numero de puerto valido"
    exit 1
  fi
}


function remove {
  ssh vagrant@$VAGRANT_IP -p $VAGRANT_PORT'rm /home/vagrant/.ssh/authorized_keys'
  echo "LLave eliminada correctamente"
  
#  if [ $1 == "only"  ]; then
    exit 0
#  fi
  
}

while getopts "hve:ni:rp:" OPTIONS; do
  case $OPTIONS in
    h) about ;;
    v) verbose ;;
    r) remove;;
    e) EXISTS_PUB=$OPTARG ;;
#    n) NEW_KEY=$OPTARG ;;
    i) setip $OPTARG ;;
    p) setport $OPTARG ;;
    *) echo "Unknown option $1"
       exit 2
       ;;
   esac
done


if [ -f $EXISTS_PUB ]; then
  echo -e $VAGRANT_INSECURE_KEY "\n" `cat $EXISTS_PUB`  | ssh vagrant@$VAGRANT_IP  -p $VAGRANT_PORT 'mkdir -p .ssh;  cat >> /home/vagrant/.ssh/authorized_keys; chmod 600 /home/vagrant/.ssh/authorized_keys'
fi

echo "LLave agrada correctamente"
