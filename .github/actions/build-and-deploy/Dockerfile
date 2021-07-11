# Container image that runs your code
FROM ruby:2.7.4

# Install packages required by the action; specifically:
# - jq (https://stedolan.github.io/jq/)
# Update bundler
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      jq && \
    gem install bundler

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
