#!/bin/bash

# Abort if exit with non-zero status
set -e

echo "Validating parameters of requested action..."

# Define the remote git repository and branch where
# we will be deploying the Jekyll-generated site to
REMOTE_REPO="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# User or organization site, thus the only publishing
# destination option is the root of the master branch
if [[ "${GITHUB_REPOSITORY}" == *".github.io" || "${GITHUB_REPOSITORY}" == *".github.com" ]]; then
  REMOTE_BRANCH="refs/heads/master"

# A project site can only be published from the master or gh-pages branch.
# Ergo, determine which branch the repository's publishing destination is.
else
  RESPONSE=$(curl \
    --header "Accept: application/vnd.github.v3+json" \
    --header "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/repos/${GITHUB_ACTOR}/${GITHUB_REPOSITORY}/pages)

  # Because I don't know what I'm doing...
  echo RESPONSE
  PUB_BRANCH=$(echo ${RESPONSE} | jq '.source.branch' | tr -d '"')
  PUB_DIR=$(echo ${RESPONSE} | jq '.source.directory' | tr -d '"')
  echo "${PUB_BRANCH} ${PUB_DIR}"
  # ...I echo this stuff to see if it works

  REMOTE_BRANCH="refs/heads/gh-pages"
fi

# Protect me from my stupidity
if [[ "${GITHUB_REF}" == "${REMOTE_BRANCH}" ]]; then
  echo "Destination (${REMOTE_BRANCH}) cannot be same as source (${GITHUB_REF})"
  exit 1
fi

echo "Parameters validated. Installing dependencies required by site..."

# Install Jekyll site dependencies as defined by the Gemfile
# @see: https://github.com/actions/cache/blob/master/examples.md#ruby---bundler
bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

echo "Dependencies installed. Building site using Jekyll..."

# Defines the directory where Jekyll shall write
# the files it generates when it builds the site
JEKYLL_DEST_DIR="./_site"

# Build the Jekyll site
# If you use the jekyll-github-metadata plugin, you must
# set JEKYLL_GITHUB_TOKEN for it to get your github data
# @see: https://github.com/jekyll/github-metadata/blob/master/docs/authentication.md
JEKYLL_ENV=production JEKYLL_GITHUB_TOKEN=${GITHUB_TOKEN} \
bundle exec jekyll build --destination ${JEKYLL_DEST_DIR} --trace --verbose

echo "Site built. Priming site for deployment..."

# Go to the directory where the Jekyll-generated site resides
cd ${JEKYLL_DEST_DIR}

# Since we are building the site using Jekyll, it would be redundant for GitHub
# Pages to build the site again. Adding a .nojekyll file avoids such a scenario
# @see: https://github.blog/2009-12-29-bypassing-jekyll-on-github-pages/
touch .nojekyll

# This file is unnecessary
rm -f README.md

echo "Site primed. Deploying site to ${REMOTE_BRANCH} branch of ${GITHUB_REPOSITORY} repository..."

# Initialize a new local git repository
git init
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# Add all files generated during the Jekyll
# build process to the local git repository
git add .

# Commit all files added to the local git repository
git commit \
    -m "A product of: ${GITHUB_WORKFLOW} workflow" \
    -m "Initiated by: ${GITHUB_ACTOR}" \
    -m "Triggered by: ${GITHUB_SHA} commit of ${GITHUB_REF} branch of ${GITHUB_REPOSITORY} repository"

# Push the commit to the gh-pages branch of the remote repository
git push --force ${REMOTE_REPO} ${GITHUB_REF}:${REMOTE_BRANCH}

echo "Site deployed. Removing files generated whilst building and deploying site..."

# Presumably, these commands are unnecessary. Presumably, the virtual machine
# used to run the GitHub Actions workflow is destroyed once the jobs are done
rm -rf .git
cd ..
bundle exec jekyll clean --destination ${JEKYLL_DEST_DIR}

echo "Files removed. All done. Huzzah!"
exit 0
