#!/bin/bash

# my steps to contributing to the EMCO repository using GitHub
# check emco_full-history.sh if you want to keep full history of your changes/notes

# assume we're in the home
cd

# always prefer SSH
emcourl=git@github.com:onap/multicloud-k8s.git
git clone $emcourl

emcodir=~/EMCO
cd $emcodir

# checkout a new (dev) branch to work on your contribution
git checkout -b feature

# note the commit ID at this point, the HEAD before you started your work
# you could even save it to a variable, if you're goign to continue in this terminal session
oldhead=$(git rev-parse HEAD)

# make your changes...

# commit at least once
git commit -a -s

# if needed, squash and/or edit your commits until you have a final set you want to submit
# (this is where knowing the HEAD before your first commit is important) 
git rebase -i $oldhead

# just in case, remember the new commit ID
lasthead=$(git rev-parse HEAD)

# push your new dev branch
git push --set-upstream origin feature

# make sure you have the GitHub CLI - in order to create/manage pull requests (PR) from the command-line:
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# https://cli.github.com/manual/gh_pr_create

# use the GitHub CLI command to create a pull request with your finalized commits
# the title and body are not of any commit, but rather the PR itself - you are talking to reviewers here
gh pr create --title "Add new great feature" --body "This introduces a novel way of doing great work." --reviewer igordcard --label enhancement

# the gh tool is pretty powerful, make sure to study all the options that are available when creating a PR:
gh pr create --help

# if the PR as it stands isn't accepted by the reviewers, your contribution needs additional changes

# again, make your changes...
# ... and commit, as often as needed to tell the story to yourself

# but there are 2 possibilities here (or a 3rd encompassing both):
# 1. you just need to provide additional commits to do something else
# 2. you need to fix your existing commits (amend them)

#
# if possibility 1

# squash like before, but only squash the new commits the you want one, or many, ready for PR review
# (this is where knowing the HEAD of the last pushed HEAD is useful)
git rebase -i $lasthead

# just in case, remember the new commit ID (as before)
lasthead=$(git rev-parse HEAD)

# push the updated branch, GitHub will detect it and update the PR accordingly with the new commit(s) added
git push

#
# if possibiity 2

# squash your intermediate commits into one, back from main's HEAD just like before
git rebase -i $oldhead

# just in case, remember the new commit ID (as before)
lasthead=$(git rev-parse HEAD)

# force-push the updated branch, GitHub will detect it and update the PR accordingly with the new commit(s) added
# the --force/-f flag is needed because in possibility 2 you are rewriting the dev branch's history (in order to provide new versions of the commits you originally proposed)
git push --force

# rinse and repeat by making more commits, rebasing, and push/force-pushing

# ...

# when the PR is accepted and the commits added upstream, please delete the dev branch from the remote
git push origin :feature
