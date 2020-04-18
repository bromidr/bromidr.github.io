#!/bin/bash

# Abort if exit with non-zero status
set -e

echo "Installing dependencies required by site..."

# Install Jekyll site dependencies as defined by the Gemfile
bundle install

echo "...done. Building site using Jekyll..."

# Defines the directory where Jekyll shall write
# the files it generates when it builds the site
JEKYLL_SITE_DEST = "./_site"

# Build the Jekyll site
JEKYLL_ENV=production bundle exec jekyll build --destination ${JEKYLL_SITE_DEST}

echo "...done. Priming site for deployment..."

# Go to the directory where the Jekyll-generated site resides
cd ${JEKYLL_SITE_DEST}

# Since we are building the site using Jekyll, it would be redundant for GitHub
# Pages to build the site again. Adding a .nojekyll file avoids such a scenario
# @see: https://github.blog/2009-12-29-bypassing-jekyll-on-github-pages/
touch .nojekyll

# This file is unnecessary
rm -f README.md

# Define the remote git repository and branch where
# we will be deploying the Jekyll-generated site to
REMOTE_REPO = "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
REMOTE_BRANCH = "gh-pages"

echo "...done. Deploying site to ${REMOTE_BRANCH} branch of ${GITHUB_REPOSITORY} repository..."

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
git push --force ${REMOTE_REPO} master:${REMOTE_BRANCH}

# Presumably, these commands are unnecessary. Presumably, the virtual machine
# used to run the GitHub Actions workflow is destroyed once the jobs are done
echo "...done. Removing files generated whilst building and deploying site..."
rm -rf .git
cd ..
bundle exec jekyll clean

echo "...done. Site built and deployed. Huzzah!"
exit 0
