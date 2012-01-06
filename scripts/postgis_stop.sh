#!/bin/sh
DATA=/Users/bartbaas/data/pgdata
echo "Stopping postgresql"
pg_ctl -D $DATA stop -s -m fast