#!/bin/bash -e

TENDERDUTY_DIR="/home/user/tenderduty"
CONFIG_DIR="/home/user/.config/tenderduty-config"
#Check if an update is needed
cd $CONFIG_DIR
git remote update

if [[ $(git status -uno | grep "behind 'origin/main'") ]]; then
    #Pull Update
    git fetch
    git pull

    #Restart tenderduty
    cd "$TENDERDUTY_DIR"
    docker-compose down
    docker-compose up -d

    #Implement check to see if restart fails
    #TODO
fi

exit 0