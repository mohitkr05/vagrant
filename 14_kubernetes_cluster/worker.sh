#!/bin/bash

HOST=" master.example.com"
COUNT=5
IFACE="enp0s8"

# Ping the host for the specified count
for ((i=1; i<=$COUNT; i++))
do
  ping -c 1 $HOST -I $IFACE
done

sudo bash /vagrant/join-worker.sh