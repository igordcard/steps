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

# emco-gui-dbupdate
docker build -t emco-gui-dbupdate:latest db_udpate
docker tag emco-gui-dbupdate:latest emco-gui-dbupdate:$EMCO_VERSION
docker tag emco-gui-dbupdate:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbupdate:$EMCO_VERSION
docker tag emco-gui-dbupdate:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbupdate:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbupdate:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-dbupdate:$EMCO_VERSION

# emco-gui-authgateway
docker build -t emco-gui-authgateway:latest authgateway
docker tag emco-gui-authgateway:latest emco-gui-authgateway:$EMCO_VERSION
docker tag emco-gui-authgateway:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgateway:$EMCO_VERSION
docker tag emco-gui-authgateway:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgateway:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgateway:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-authgateway:$EMCO_VERSION

# emco-gui-middleend
docker build -t emco-gui-middleend:latest guimiddleend
docker tag emco-gui-middleend:latest emco-gui-middleend:$EMCO_VERSION
docker tag emco-gui-middleend:$EMCO_VERSION registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:$EMCO_VERSION
docker tag emco-gui-middleend:latest registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:latest
docker push registry.gitlab.com/project-emco/ui/emco-gui/emco-gui-middleend:$EMCO_VERSION
