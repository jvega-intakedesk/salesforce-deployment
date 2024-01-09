#!/bin/bash

function print_ruler() {
    str=''
    for (( i=1; i<=100; i++ ))
    do
        str+="="
    done

    echo ${str}
}

function pad () { 
    [ "$#" -gt 1 ] && [ -n "$2" ] && printf "%$2.${2#-}s" "$1"; 
}

print_ruler 
echo "| $( pad "This script must be copied and executed within the SalesForce project repo." -97)|"
echo "| $( pad "It will execute almost every command that is required for a delta deploy." -97)|"
echo "| $( pad "All commands will be executed under --dry-run mode." -97)|"
echo "| $( pad " " -97)|"
echo "| $( pad "To execute the command: ./local-deployment-dry-run branch-to-compare-name local-branch-name username-or-alias" -97)|"
print_ruler


RED="\033[0;31m"
NC="\033[0m"
ERROR=false

if [ -z "$1" ]; then
    echo " "
    echo -e "${RED} - The branch to compare name is a required parameter. ${NC}"
    ERROR=true
fi

if [ -z "$2" ]; then
    echo " "
    echo -e "${RED} - The local branch name is a required paramter. ${NC}"
    ERROR=true
fi

if [ -z "$3" ]; then
    echo " "
    echo -e "${RED} - The username or alias is required. ${NC}"
    ERROR=true
fi

if [ "$ERROR" = true ]; then
    exit 1
fi

echo " "
git fetch origin "+refs/heads/*:refs/remotes/origin/*"
sf sgd source delta --from "origin/$1" --to "origin/$2" --output . --generate-delta --source force-app/

DEPLOY_COMMAND="sf project deploy start --dry-run --verbose --manifest package/package.xml"

if [ -f destructiveChanges/destructiveChanges.xml ]; then
    DEPLOY_COMMAND+=" --post-destructive-changes destructiveChanges/destructiveChanges.xml"
fi

DEPLOY_COMMAND+=" --test-level RunLocalTests -o $3"

echo -e "${RED} Executing command: ${NC}"
echo -e "${RED} ${DEPLOY_COMMAND} ${NC}"

${DEPLOY_COMMAND[@]}