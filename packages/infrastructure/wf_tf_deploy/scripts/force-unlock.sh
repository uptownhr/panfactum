#!/usr/bin/env bash

set -eo pipefail

#####################################################
# Step 1: Clone the repo
#####################################################
cd /code
git clone --depth=1 "https://$PF_REPO_URL.git" repo
cd repo
git fetch origin "$GIT_REF"
git checkout "$GIT_REF"
git lfs install --local
git lfs pull

#####################################################
# Step 2: Setup AWS profile
#####################################################
export AWS_CONFIG_FILE="/.aws/config"
cat >"$AWS_CONFIG_FILE" <<EOF
[profile ci]
role_arn = $AWS_ROLE_ARN
web_identity_token_file = /var/run/secrets/eks.amazonaws.com/serviceaccount/token
role_session_name = ci-runner
EOF

#####################################################
# Step 3: Get the lock table and region
#####################################################
TG_VARIABLES=$(pf-get-terragrunt-variables "$TF_APPLY_DIR")
LOCK_TABLE=$(echo "$TG_VARIABLES" | jq '.tf_state_lock_table' -r)
LOCK_TABLE_REGION=$(echo "$TG_VARIABLES" | jq '.tf_state_region' -r)

#####################################################
# Step 4: Unlock
#####################################################
pf-tf-delete-locks \
  --profile ci \
  --region "$LOCK_TABLE_REGION" \
  --table "$LOCK_TABLE" \
  --who "$WHO"
