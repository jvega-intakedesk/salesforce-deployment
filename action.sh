#!/bin/bash

# Inputs
DRY_RUN=true
TEST_LEVEL=RunLocalTests
TIMEOUT=30
MANIFEST_SOURCE_DIRECTORY=force-app
MANIFEST_OUTPUT_DIRECTORY=manifest
PACKAGE_SOURCE_DIRECTORY=manifest/package.xml
DELTA_SOURCE_DIRECTORY=package/package.xml
DELTA_FROM_SOURCE="HEAD^1"
DELTA_TO_SOURCE="HEAD"
SF_AUTH_URL=''
SF_AUTH_USERNAME="csilva@intakedesk.com"

echo ""
echo "RUNNING: README"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug:: Add here the number of times you changed this and it broke:"
echo "::debug::               ,     \    /      ,"
echo "::debug::              / \    )\__/(     / \\"
echo "::debug::             /   \  (_\  /_)   /   \\"
echo "::debug::____________/_____\__\@  @/___/_____\___________"
echo "::debug::|                    |\../|                    |"
echo "::debug::|                     \VV/                     |"
echo "::debug::|                                              |"
echo "::debug::|                      35                      |"
echo "::debug::|______________________________________________|"
echo "::debug::        |    /\ /      \\       \ /\    |"
echo "::debug::        |  /   V        ))       V   \  |"
echo "::debug::        |/             //              \|"
echo "::debug::                       V"

echo ""
echo "RUNNING: Printing Github Variables in debug mode"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug:: CI : $CI"
echo "::debug::GITHUB_WORKFLOW : $GITHUB_WORKFLOW"
echo "::debug::GITHUB_RUN_ID : $GITHUB_RUN_ID"
echo "::debug::GITHUB_RUN_NUMBER : $GITHUB_RUN_NUMBER"
echo "::debug::GITHUB_ACTION : $GITHUB_ACTION"
echo "::debug::GITHUB_ACTIONS : $GITHUB_ACTIONS"
echo "::debug::GITHUB_ACTOR : $GITHUB_ACTOR"
echo "::debug::GITHUB_REPOSITORY : $GITHUB_REPOSITORY"
echo "::debug::GITHUB_EVENT_NAME : $GITHUB_EVENT_NAME"
echo "::debug::GITHUB_EVENT_PATH : $GITHUB_EVENT_PATH"
echo "::debug::GITHUB_WORKSPACE : $GITHUB_WORKSPACE"
echo "::debug::GITHUB_SHA : $GITHUB_SHA"
echo "::debug::GITHUB_REF : $GITHUB_REF"
echo "::debug::GITHUB_HEAD_REF : $GITHUB_HEAD_REF"
echo "::debug::GITHUB_BASE_REF : $GITHUB_BASE_REF"
echo "::debug::GITHUB_SERVER_URL : $GITHUB_SERVER_URL"
echo "::debug::GITHUB_API_URL : $GITHUB_API_URL"
echo "::debug::GITHUB_GRAPHQL_URL : $GITHUB_GRAPHQL_URL"
echo "::debug::BRANCH_NAME : ${{ github.event.pull_request.head.ref }}"
echo "::debug::GITHUB_REF : $GITHUB_REF"

echo ""
echo "RUNNING: Installing Required system libraries"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug::  SKIPPED: sudo apt-get update"
echo "::debug::  SKIPPED: sudo apt-get install default-jdk"
echo "::debug::  SKIPPED: sudo apt-get install xmlstarlet"
echo "::debug::  SKIPPED: sudo npm install -g npm@latest"
echo "::debug::  SKIPPED: sudo npm install -g n"
echo "::debug::  SKIPPED: sudo n lts"

echo ""
echo "RUNNING: Install Salesforce CLI"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug::  SKIPPED: npm install -g @salesforce/cli"
sf version --verbose --json

echo ""
echo "RUNNING: Installing SF Git Delta Plugin"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug::  SKIPPED: echo y | sf plugins install sfdx-git-delta"
sf plugins

echo ""
echo "RUNNING: Environment Login"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug::  SKIPPED: sf org login sfdx-url --set-default --sfdx-url-file <(echo \"$SF_AUTH_URL\")"

echo ""
echo "RUNNING: Checkout source code"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug::  SKIPPED: 3rd party"

echo ""
echo "RUNNING: Creating Delta packages for new, modified or deleted metadata"
echo "--------------------------------------------------------------------------------------------------------"
echo "::debug:: Command being executed: sf sgd source delta --from \"$DELTA_FROM_SOURCE\" --to \"$DELTA_TO_SOURCE\" --output . --source $MANIFEST_SOURCE_DIRECTORY/ --generate-delta"
sf sgd source delta --from "$DELTA_FROM_SOURCE" --to "$DELTA_TO_SOURCE" --output . --source $MANIFEST_SOURCE_DIRECTORY/ --generate-delta

echo ""
echo "RUNNING: Determining Specified Tests"
echo "--------------------------------------------------------------------------------------------------------"
if [ "$DRY_RUN" = "true" ] && [ -f "$DELTA_SOURCE_DIRECTORY" ]; then
    content=$(cat $DELTA_SOURCE_DIRECTORY)

    echo "::debug:: XML Content:"
    echo "::debug:: $content"

    filtered_members=$(echo "$content" | xmlstarlet sel -N ns="http://soap.sforce.com/2006/04/metadata" \
        -t -m "//ns:types[ns:name='ApexClass']/ns:members[not(contains(., 'Test'))]" -v . -n)

    test_classes=()

    echo "::debug:: filtered_members Content:"
    echo "::debug:: $filtered_members"

    # Save each member into run-tests.txt with "Test" appended and quotes if there are spaces
    > run-tests.txt

    # Read each line from filtered_members and concatenate them into deployFlagsConcatenated
    while IFS= read -r member; do
        # Append "Test" to the member without quotes
        if [[ -n "$member" ]]; then
            echo "${member}Test " >> run-tests.txt
        fi
    done <<< "$filtered_members"

    echo "::debug:: Contents of run-tests.txt:"
    runTestsContent=$(cat run-tests.txt)
    echo "::debug:: $runTestsContent"
else
    echo "::debug:: No package changes found"
    > run-tests.txt
fi

echo ""
echo "RUNNING: Environment Package(s) Deployment"
echo "--------------------------------------------------------------------------------------------------------"

# To ensure that we are always testing with dry-run
deployFlags=(
    --wait $TIMEOUT
    --dry-run
)

testRunContents=$(cat run-tests.txt);
echo "::debug:: $testRunContents"

hasTests=false

if [ "$DRY_RUN" = "true" ]; then
    classesToRun=$(cat "run-tests.txt")
    # deployFlags+=( --dry-run )
    deployFlags+=( --verbose )
    
    # deployFlags+=( --test-level ${{ inputs.TEST_LEVEL }} )

    # deployFlags+=( --tests $classesToRun )
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            hasTests=true
            deployFlags+=(--tests $line)
        fi
    done < "run-tests.txt"
    echo "::debug:: HAS TESTS $hasTests"

    if [ "$hasTests" = "false" ]; then
        deployFlags+=( --test-level $TEST_LEVEL )
    else
        deployFlags+=( --test-level RunSpecifiedTests )
    fi

else
    deployFlags+=( --test-level $TEST_LEVEL )
fi

if [ ! -z "$SF_AUTH_USERNAME" ]; then
    deployFlags+=( -o $SF_AUTH_USERNAME )
fi

if [ -f $DELTA_SOURCE_DIRECTORY ]; then
    echo "::debug:: Deploying Package(s) Changes: $DELTA_FROM_SOURCE to $DELTA_TO_SOURCE @ $GITHUB_REPOSITORY"
    echo "::debug:: Delta Contents: $( cat $DELTA_SOURCE_DIRECTORY )"

    deployFlags+=(
        --manifest $DELTA_SOURCE_DIRECTORY
    )
else
    echo "::debug::No changes to deploy between $GITHUB_BASE_REF and $GITHUB_HEAD_REF @ $GITHUB_REPOSITORY"
fi

if [ -f destructiveChanges/destructiveChanges.xml ]; then
    echo "::debug:: Deploying Package(s) Destructive Changes: $DELTA_FROM_SOURCE to $DELTA_TO_SOURCE @ $GITHUB_REPOSITORY"
    echo "::debug:: Destructive Changes Contents: $( cat destructiveChanges/destructiveChanges.xml )"

    deployFlags+=(
        --post-destructive-changes destructiveChanges/destructiveChanges.xml
    )
else
    echo "::debug:: No Destructive changes to deploy between $DELTA_FROM_SOURCE to $DELTA_TO_SOURCE @ $GITHUB_REPOSITORY"
fi

echo "::debug:: Command being executed: sf project deploy start ${deployFlags[@]}"

# sf project deploy start "${deployFlags[@]}"