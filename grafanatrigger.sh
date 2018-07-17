#!/bin/bash
GITREPO="https://github.com/grafana/grafana.git"
BRANCH="master"
OLDSHAFILE="./OLDSHA"
DOCKERREPO=""
DOCKERTAG="latest"
TRIGGERID=""
OLDSHA=`cat ${OLDSHAFILE}`
NEWSHA=`git ls-remote ${GITREPO} ${BRANCH} | cut -f1`
if [[ ${NEWSHA} !=  ${OLDSHA} ]]; then
    curl -H "Content-Type: application/json" --data '{"docker_tag": "'${DOCKERTAG}'"}' -X POST https://registry.hub.docker.com/u/${DOCKERREPO}/trigger/${TRIGGERID}/
    echo "${NEWSHA}" > ${OLDSHAFILE}
fi
exit 0
