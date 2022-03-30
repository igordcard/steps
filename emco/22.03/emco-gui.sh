# build and push all emco-gui images to GitLab container registry (release time)

EMCO_VERSION=22.03

cd emco-gui # this is the git repo dir
docker login registry.gitlab.com

# emco-gui
docker build -t emco-gui:latest .
docker tag emco-gui:latest emco-gui:$EMCO_VERSION
docker tag emco-gui:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui:$EMCO_VERSION
docker tag emco-gui:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui:$EMCO_VERSION

# emco-gui-dbhook
docker build -t emco-gui-dbhook:latest db_udpate
docker tag emco-gui-dbhook:latest emco-gui-dbhook:$EMCO_VERSION
docker tag emco-gui-dbhook:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbhook:$EMCO_VERSION
docker tag emco-gui-dbhook:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbhook:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbhook:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbhook:$EMCO_VERSION

# emco-gui-authgw
docker build -t emco-gui-authgw:latest authgateway
docker tag emco-gui-authgw:latest emco-gui-authgw:$EMCO_VERSION
docker tag emco-gui-authgw:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgw:$EMCO_VERSION
docker tag emco-gui-authgw:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgw:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgw:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgw:$EMCO_VERSION

# emco-gui-middleend
docker build -t emco-gui-middleend:latest guimiddleend
docker tag emco-gui-middleend:latest emco-gui-middleend:$EMCO_VERSION
docker tag emco-gui-middleend:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:$EMCO_VERSION
docker tag emco-gui-middleend:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:$EMCO_VERSION
