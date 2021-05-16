#!/bin/bash

# start with no deployed clusters

alias emcoctl='$EMCO_DIR/bin/emcoctl/emcoctl'

export KUBE_PATH=~/c01.config
export HOST_IP=localhost

cd $EMCO_DIR/kud/emcoctl-tests
./setup.sh create

# fix yamls for local non-k8s EMCO deployment:
cp $EMCO_DIR/src/tools/emcoctl/examples/emco-cfg.yaml .
sed -i "s/30441/9031/" values.yaml

# setup for L1+ compatible prometheus-operator:
mkdir l1
mv output values.yaml emco-cfg.yaml l1/
cp prerequisites.yaml test-prometheus-collectd.yaml l1/

## The modified yaml files for L1+ are not specified here.
####

# install
emcoctl --config emco-cfg.yaml apply -f prerequisites.yaml -v values.yaml
emcoctl --config emco-cfg.yaml apply -f test-prometheus-collectd.yaml -v values.yaml

# remove
emcoctl --config emco-cfg.yaml delete -f test-prometheus-collectd.yaml -v values.yaml
emcoctl --config emco-cfg.yaml delete -f prerequisites.yaml -v values.yaml
