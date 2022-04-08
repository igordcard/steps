# Updated for 22.03:
#####################################

# Drop database:
docker exec -it deployments_mongo_1 mongo emco --eval "db.dropDatabase()"
#or
mongo $MONGO_IP/emco --eval "db.dropDatabase()"

# Count resources in database:
docker exec -it deployments_mongo_1 mongo emco --eval "db.resources.count()"
# or 
mongo $MONGO_IP/emco --eval "db.resources.count()"

# Find resources in database:
docker exec -it deployments_mongo_1 mongo emco --eval "db.resources.find()"
# or 
mongo $MONGO_IP/emco --eval "db.resources.find()"


# Archived from prior releases:
#####################################

# Delete everything in MongoDB with authentication:
# MONGO_IP=localhost #optional
mongo --username $MONGO_IP/emco --password emco mco --eval 'db.orchestrator.remove({})'
mongo --username $MONGO_IP/emco --password emco mco --eval 'db.cluster.remove({})'
mongo --username $MONGO_IP/emco --password emco mco --eval 'db.cloudconfig.remove({})'
mongo --username $MONGO_IP/emco --password emco mco --eval 'db.controller.remove({})'

# Delete everything in MongoDB without authentication:
# MONGO_IP=localhost #optional
mongo $MONGO_IP/mco --eval 'db.orchestrator.remove({})'
mongo $MONGO_IP/mco --eval 'db.cluster.remove({})'
mongo $MONGO_IP/mco --eval 'db.cloudconfig.remove({})'
mongo $MONGO_IP/mco --eval 'db.controller.remove({})'

# Show MongoDB store collections:
mongo $MONGO_IP/mco --eval 'db.cluster.find()'
mongo $MONGO_IP/mco --eval 'db.cloudconfig.find()'
mongo $MONGO_IP/mco --eval 'db.orchestrator.find()'

# Count how many documents in a collection:
mongo $MONGO_IP/mco --eval 'db.cloudconfig.count()'

# Delete specific MongoDB document by ID:
mongo $MONGO_IP/mco --eval 'db.orchestrator.remove({"_id" : ObjectId("5fb42624bbc56bb17e02b5d7")})'

# Delete all MongoDB records except one:
mongo $MONGO_IP/mco --eval 'db.orchestrator.remove({"_id" : { $ne: ObjectId("5fb4228dbbc56bb17e02b392")}})'

# Update specific MongoDB document by ID:
mongo $MONGO_IP/mco --eval 'db.orchestrator.update({"_id" : ObjectId("5fb4228dbbc56bb17e02b392")}, { "_id" : ObjectId("5fb4228dbbc56bb17e02b392"), "project" : "test-project", "key" : "{project,}", "projectmetadata" : { "metadata" : { "name" : "test-project", "description" : "description of test-project project", "userdata1" : "test-project user data 1", "userdata2" : "test-project user data 2" } } })'
mongo $MONGO_IP/mco --eval 'db.cluster.update({"_id" : ObjectId("5fb5f804bbc56bb17e03e36b")}, { "_id" : ObjectId("5fb5f804bbc56bb17e03e36b"), "cluster" : "c1", "label" : "LabelA", "provider" : "cp", "clustermetadata" : { "labelname" : "LabelA" }, "key" : "{cluster,label,provider,}" })'

# Reset typical EMCO collections to a fresh-ish state
mongo $MONGO_IP/mco --eval 'db.cloudconfig.remove({"cluster":"c1","level":"1"})'

