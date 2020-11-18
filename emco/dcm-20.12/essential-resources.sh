#!/bin/bash

export orchestrator=http://localhost:9015/v2
export clm=http://localhost:9061/v2
export emcoroot=~/EMCO

# create a project compatible with emco.sh
projectname="test-project"
projectdata="$(cat<<EOF
{
  "metadata": {
    "name": "$projectname",
    "description": "description of $projectname controller",
    "userData1": "$projectname user data 1",
    "userData2": "$projectname user data 2"
  }
}
EOF
)"
curl -X POST "$orchestrator/projects" -d "$projectdata"
