#!/bin/bash

# Abort if exit with non-zero status
set -e

echo "Installing dependencies required by site..."

# Install Jekyll site dependencies as defined by the Gemfile
# @see: https://github.com/actions/cache/blob/master/examples.md#ruby---bundler
bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

echo "Dependencies installed. Building site using Jekyll..."

# Defines the directory where Jekyll shall write
# the files it generates when it builds the site
JEKYLL_SITE_DEST="./_site"

# Build the Jekyll site
# If you use the jekyll-github-metadata plugin, you must
# set JEKYLL_GITHUB_TOKEN for it to get your github data
# @see: https://github.com/jekyll/github-metadata/blob/master/docs/authentication.md
JEKYLL_ENV=production JEKYLL_GITHUB_TOKEN=${GITHUB_TOKEN} \
bundle exec jekyll build --destination ${JEKYLL_SITE_DEST}

echo "Site built. Priming site for deployment..."

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
REMOTE_REPO="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
REMOTE_BRANCH="gh-pages"

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

# Presumably, these commands are unnecessary. Presumably, the virtual machine
# used to run the GitHub Actions workflow is destroyed once the jobs are done
echo "Site deployed. Removing files generated whilst building and deploying site..."
rm -rf .git
cd ..
bundle exec jekyll clean

echo "Files removed. All done. Huzzah!"
exit 0
