# IntakeDesk Salesforce Deployment Script for GitHub Actions

This action will build a `package.xml` and deploy to a specified Salesforce environment. This is a variation from the 
`jawills/sf-deploy` project.

## Inputs

|INPUT         |Optional|Type     |Default Value|Options|Description|
|--------------|:------:|:-------:|:-----------:|:-----:|:---------:|
|SF_AUTH_URL|N|string|-|-|The Salesforce Auth URL.|
|DRY_RUN|Y|boolean|true|-|Enable or disable the Salesforce project deploy `--dry-run` flag.|
|TEST_LEVEL|Y|option|RunLocalTests|NoTestRun, RunSpecifiedTests, RunLocalTests, RunAllTestsInOrg|Salesforce project deploy `--test-level` parameter. Defaults to RunLocalTests.|
|TIMEOUT|Y|number|30|-|Salesforce project deploy `--wait` flag value. Timeout in minutes for the command to complete and display results|
|MANIFEST_SOURCE_DIRECTORY|Y|string|force-app|-|Source files path for project manifest generation `--source-dir` flag.|
|MANIFEST_OUTPUT_DIRECTORY|Y|string|manifest|-|Output directoryfor project manifest generation `--output-dir` flag.|
|VERBOSE|Y|boolean|true|-|Enable or disable the Salesforce project deploy flag for `--verbose` flag.|
|PACKAGE_SOURCE_DIRECTORY|Y|string|manifest/package.xml|-|Salesforce project deploy `--manifest` file path flag.|


## Usage

To get the required SF_AUTH_URL, use the following command in your terminal.

```bash
sf org display --verbose --json -o <TARGET_ORG_ALIAS_OR_USERNAME>
```

On your GitHub action add as part of a step. Example:

```yml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        uses: intakedesk/salesforce-deployment@v1.0
        with:
          SF_AUTH_URL: ${{ secrets.SF_AUTH_URL }}
          DRY_RUN: true
          TEST_LEVEL: RunLocalTests
          TIMEOUT: 30
          MANIFEST_SOURCE_DIRECTORY: force-app
          MANIFEST_OUTPUT_DIRECTORY: manifest
          VERBOSE: true
          PACKAGE_SOURCE_DIRECTORY: manifest/package.xml
```
