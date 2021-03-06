#!/bin/bash

MAIN_BRANCH=$TRAVIS_BRANCH
TARGET_BRANCH="pac"

# Pull requests shouldn't try to deploy, just skip
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "Skipping."
    exit 0
fi

# Get the deploy key
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Config git
git config --global user.name "Travis CI"
git config --global user.email "$COMMIT_AUTHOR_EMAIL"

# Build information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Build
mkdir out
python2 main.py -o out/whitelist.pac

# Init git dir
git clone --depth=1 --branch=$TARGET_BRANCH $REPO orig

if [ $? -eq 0 ];then
    cd out
    mv ../orig/.git .git
else
    cd out
    git init
    git checkout --orphan $TARGET_BRANCH
    git remote add repo $REPO
fi

# Add all
git add --all .
git commit -m "Deploy to pac branch: ${SHA}"

# Push it
git push $SSH_REPO $TARGET_BRANCH -f
