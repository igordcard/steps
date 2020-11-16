#!/bin/bash
orchestrator=http://localhost:9015/v2
clm=http://localhost:9061/v2
emcoroot=~/EMCO

# modify plugin_fw_v2.sh to match dev env

# instantiate vs. terminate
cd $emcoroot/kud/tests
./plugin_fw_v2.sh setup
./plugin_fw_v2.sh create
./plugin_fw_v2.sh apply

# a reasonable test sequence:
# 1.  create
# 2.  apply
# 3.  instantiate
# 4.  status
# 5.  terminate
# 6.  destroy

# rinse and repeat:
./plugin_fw_v2.sh instantiate
./plugin_fw_v2.sh wait
./plugin_fw_v2.sh status
./plugin_fw_v2.sh terminate
