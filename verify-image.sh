#!/usr/bin/env bash
set -e

export DOCKER_CLI_HINTS=false

# strip the 'sha256:' prefix
image_sha256="$1"
digest="${image_sha256/sha256:/}"
repo_name="$2"
purl="${3}"

docker pull --quiet develocitytia.jfrog.io/docker-ci/develocity-attestation-verifier:main

set +e # this next line could fail
POLICY_RESULT=$(docker run \
  -e JF_ACCESS_TOKEN \
  --volume $(pwd)/policies/qa.rego:/work/qa.rego \
  develocitytia.jfrog.io/docker-ci/develocity-attestation-verifier:main \
    /work/qa.rego \
    "${digest}" \
    "https://develocitytia.jfrog.io" \
    "${repo_name}")

POLICY_STATUS=$?

set -e # re-enable failures

if [ $POLICY_STATUS -ne 0 ]
then

  echo
  echo "::warning file:workflows/qa.yaml title=Policy Validation Failed::$POLICY_RESULT"

  echo "verifier_status=failed" >> "$GITHUB_OUTPUT"

  cat << EOF > ${GITHUB_STEP_SUMMARY}
## Image Verification Failed

**Image:** \`${purl}\`

**Digest:** \`${digest}\`

\`\`\`txt
$POLICY_RESULT
\`\`\`

EOF
fi

exit $POLICY_STATUS
