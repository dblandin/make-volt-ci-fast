#! /usr/bin/env bash
#
# REQUIRES THESE ENVIRONMENT VARIABLES SET:
#    BUNDLE_GITHUB__COM 
#    CIRCLE_PROJECT_USERNAME 
#    CIRCLE_PR_REPONAME
#    CIRCLE_PR_NUMBER
#  
# This script attempts to fetch information on a Github PR
# and returns an error if the PR is a draft PR or contains
# "skip ci", "ci skip", or "wip". Written to be used in 
# conjunction with Github and CircleCI

# {{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
# }}}

required_env_vars=(
  "BUNDLE_GITHUB__COM"
  "CIRCLE_PROJECT_USERNAME"
  "CIRCLE_PR_REPONAME"
  "CIRCLE_PR_NUMBER"
)

for required_env_var in ${required_env_vars[@]}; do
  if [[ -z "${!required_env_var}" ]]; then
    printf "${required_env_var} not provided, but that doesn't mean we should skip CI.\n"
    exit 0
  fi
done

# Since we're piggybacking off of an existing OAuth var, tweak the var for our uses
token=$(cut -d':' -f1 <<< "${BUNDLE_GITHUB__COM}")

headers="Authorization: token $token"
api_endpoint="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PR_REPONAME}/pulls/${CIRCLE_PR_NUMBER}"

# Fetch PR metadata from Github's API and parse fields from json
github_res=$(curl --silent --header "${headers}" "${api_endpoint}" | jq '{mergeable_state: .mergeable_state, title: .title}')
mergeable_state=$(printf "${github_res}" | jq '.mergeable_state')
title=$(printf "${github_res}" | jq '.title' | tr '[:upper:]' '[:lower:]')

if [[ "${title}" == "null" && "${mergeable_state}" == "null" ]]; then
  printf "Couldn't fetch info on PR, but that doesn't mean we should skip CI.\n"
  exit 0
fi

if [[ "${mergeable_state}" == "\"draft\"" ]]; then
  printf "PR is a draft, skipping CI!\n"
  exit 1
fi

for skip_token in 'skip ci' 'ci skip' 'wip'; do
  if [[ ${title} == *"${skip_token}"* ]]; then
    printf "Found \"${skip_token}\" in PR title, skipping CI!\n"
    exit 1
  fi
done

exit 0
