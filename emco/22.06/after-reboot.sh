#!/bin/bash

docker start root_etcd_1
docker start deployments_mongo_1
docker start registry

cd /root/vagrant/k23-1
vagrant up
cd /root/vagrant/k22-1
vagrant up

# restart all EMCO services (usually in tmux)
EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/orchestrator
killall orchestrator
./orchestrator >> log.txt 2>&1 &
sleep 2 # give it a bit time to make sure orchestrator creates referential integrity db resources before other services can run
cd $EMCO_DIR/bin/rsync
killall rsync
./rsync >> log.txt 2>&1 &
cd $EMCO_DIR/bin/clm
killall clm
./clm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/dcm
killall dcm
./dcm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/ncm
killall ncm
./ncm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/ovnaction
killall ovnaction
./ovnaction >> log.txt 2>&1 &
cd $EMCO_DIR/bin/dtc
killall dtc
./dtc >> log.txt 2>&1 &
cd $EMCO_DIR/bin/genericactioncontroller
killall genericactioncontroller
./genericactioncontroller >> log.txt 2>&1 &

hardreset_emco
