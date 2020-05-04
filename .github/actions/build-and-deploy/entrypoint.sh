#!/bin/bash

# Abort if exit with non-zero status
set -e

echo "Validating parameters of requested action..."

# Look for the Gemfile; ideally it would be in the current working
# directory (GITHUB_WORKSPACE) but let us not make that assumption
GEMFILE_LOC="$(find . -type d -path './vendor' -prune -o -type f -name 'Gemfile' -exec echo {} \;)"
if [[ -z "${GEMFILE_LOC}" ]]; then
  echo "Cannot find Gemfile"
  exit 1
else
  echo "...Gemfile: ${GEMFILE_LOC}"
fi

# Look for the Gemfile.lock. This file is required because the deployment
# option is set to true in the bundle config. See below for more details.
if [[ -z "$(find . -type d -path './vendor' -prune -o -type f -name 'Gemfile.lock' -exec echo {} \;)" ]]; then
  echo "Cannot find Gemfile.lock"
  exit 1
fi

# Look for the root of the source directory
SRC_DIR="$(find . -type d -path './vendor' -prune -o -type f -name '_config.yml' -exec dirname {} \;)"
if [[ -z "${SRC_DIR}" ]]; then
  echo "Cannot find _config.yml"
  exit 1
else
  SRC_DIR="${SRC_DIR}/"
  echo "...Source Directory: ${SRC_DIR}"
fi

# Define the remote git repository where the
# Jekyll-generated site ought to be deployed
REMOTE_REPO="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Get information about a GitHub Pages site; specifically, I want
# to know the repository's publishing source branch and directory
# @see: https://developer.github.com/v3/repos/pages/
API_RESPONSE=$(curl \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --request GET \
  --url https://api.github.com/repos/${GITHUB_REPOSITORY}/pages)

# If it is a user or organization site, then the value of DEST_BRANCH will equal
# "master" whilst the value of DEST_DIR will equal "/". On the other hand, if it
# is a project repo site, then the value of DEST_BRANCH shall either be "master"
# or "gh-pages". For project site, if the value of DEST_BRANCH equal "gh-pages",
# then the value of DEST_DIR can only be "/". On the other hand, if the value of
# DEST_BRANCH for project sites is "master", then DEST_DIR can be "/" or "/docs"
# @see: https://help.github.com/en/github/working-with-github-pages/about-github-pages#publishing-sources-for-github-pages-sites
DEST_BRANCH="refs/heads/$(echo ${API_RESPONSE} | jq '.source.branch' | tr -d '"')"
DEST_DIR=".$(echo ${API_RESPONSE} | jq '.source.path' | tr -d '"')"

# Protects me from my stupidness. The source branch cannot be the same as
# the destination branch if source directory is equals to the destination
# directory. They can be the same if the source and destination directory
# are different. This is the case when "/" of master branch is the source
# directory whilst "/docs" of the master branch is destination directory.
if [[ "${GITHUB_REF}" == "${DEST_BRANCH}" && "${SRC_DIR}" == "${DEST_DIR}" ]]; then
  echo "Destination (Branch: ${DEST_BRANCH}, Directory: ${DEST_DIR}) cannot be same as source (Branch: ${GITHUB_REF}, Directory: ${SRC_DIR})"
  exit 1
fi

# if the github pages' publishing source directory is the root of the repository
# then output the Jekyll-generated site to the "./_site" directory (the default)
if [[ "${DEST_DIR}" == "./" ]]; then
  DEST_DIR="./_site"

# if the github pages' publishing source directory is the "./docs" folder, must
# remove previous version before new version is Jekyll-generated to that folder
elif [[ "${DEST_DIR}" == "./docs" ]]; then
  rm -rf "${DEST_DIR}"
fi

echo "Parameters validated. Installing dependencies required by site..."

# Installs Jekyll site dependencies. Since the deployment config option is used,
# a Gemfile.lock file is needed to ensure that the same versions of the gems you
# developed and tested with are also used in deployments. Thus, the existence of
# a Gemfile and Gemfile.lock in your repository is required and validated above.
# @see: https://bundler.io/v2.0/man/bundle-install.1.html#DEPLOYMENT-MODE
# @see: https://bundler.io/v2.0/guides/deploying.html#deploying-your-application
# @see: https://github.com/actions/cache/blob/master/examples.md#ruby---bundler
bundle config --local set deployment true
bundle config --local set gemfile ${GEMFILE_LOC}
bundle config --local set path vendor/bundle
bundle config list # for debugging purposes
bundle install --jobs 4 --retry 3

echo "Dependencies installed. Building site using Jekyll..."

# Build the Jekyll site
# If you use the jekyll-github-metadata plugin, you must
# set JEKYLL_GITHUB_TOKEN for it to get your github data
# @see: https://github.com/jekyll/github-metadata/blob/master/docs/authentication.md
JEKYLL_ENV=production JEKYLL_GITHUB_TOKEN=${GITHUB_TOKEN} \
bundle exec jekyll build --source ${SRC_DIR} --destination ${DEST_DIR} --profile --trace --verbose

echo "Site built. Priming site for deployment..."

# Go to the directory where the Jekyll-generated site resides
cd ${DEST_DIR}

# Since we are building the site using Jekyll, it would be redundant for GitHub
# Pages to build the site again. Adding a .nojekyll file avoids such a scenario
# @see: https://github.blog/2009-12-29-bypassing-jekyll-on-github-pages/
touch .nojekyll

# This file is unnecessary
rm -f README.md

echo "Site primed. Deploying site to ${DEST_BRANCH} branch of ${GITHUB_REPOSITORY} repository..."

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

# Push the commit to the remote repository's publishing source branch
git push --force ${REMOTE_REPO} ${GITHUB_REF}:${DEST_BRANCH}

echo "Site deployed. Removing files generated whilst building and deploying site..."

# Presumably, these commands are unnecessary. Presumably, the virtual machine
# used to run the GitHub Actions workflow is destroyed once the jobs are done
rm -rf .git
cd ..
bundle exec jekyll clean --source ${SRC_DIR} --destination ${DEST_DIR}

echo "Files removed. All done. Huzzah!"
exit 0
