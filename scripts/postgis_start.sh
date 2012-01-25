#!/bin/sh
DIR=$(dirname $(which $0))
DATA=/Users/bartbaas/data/pgdata

#Changing shared memory resources
echo "Setting the right shared memory resources"
sudo sysctl -w kern.sysv.shmmax=33554432
sudo sysctl -w kern.sysv.shmmin=1
sudo sysctl -w kern.sysv.shmmni=256
sudo sysctl -w kern.sysv.shmseg=64
sudo sysctl -w kern.sysv.shmall=8192

#Starting postgres
echo "Starting postgresql"
#pg_ctl -D /usr/local/var/postgres -l $DIR/server.log -D $DATA start
pg_ctl -D $DATA -l $DIR/server.log start

