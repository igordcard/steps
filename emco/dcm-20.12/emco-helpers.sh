#!/bin/bash

# just some helper commands to aid
# in developing the features for 20.12

orchestrator=http://localhost:9015/v2

# create a project compatible with emco.sh
projectname="Sanity-Test-Project"
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


# create a generic placement intent
generic_placement_intent_name="test-generic-placement-intent"
generic_placement_intent_data="$(cat <<EOF
{
   "metadata":{
      "name":"${generic_placement_intent_name}",
      "description":"${generic_placement_intent_name}",
      "userData1":"${generic_placement_intent_name}",
      "userData2":"${generic_placement_intent_name}"
   }
}
EOF
)"
curl -X POST "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents" -d "${generic_placement_intent_data}"

# get the generic placement intent (to verify)
curl -X GET "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents/${generic_placement_intent_name}"

# delete the generic placement intent
curl -X DELETE "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents/${generic_placement_intent_name}"