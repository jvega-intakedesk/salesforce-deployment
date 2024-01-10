# Salesforce Deployment Script for GitHub Actions

This process involves the creation of a package.xml and subsequent deployment to a designated Salesforce environment. The generation of the delta is facilitated through [sf sgd source delta](https://github.com/scolladon/sfdx-git-delta) as a reference. It's important to note that while this plugin, though not officially supported by Salesforce, is widely adopted within the community for its effective usage.

#### Note
A ***delta*** is the difference between the files or 2 set of files. In the context of Salesforce the delta will be the difference of components, classes, etc that are in the local/sandbox version against the production one. The issue is that Salesforce, unless correctly specified, will deploy everything like a compiled application which can be time consuming. The delta generated here will be all new entities that are in one environemnt and another and all entities that are now removed. If using  `sg sgd source delta` is not something you want to use, then you can manually create the `package/package.xml`, `destructiveChanges/destructiveChanges.xml` and `destructiveChanges/package.xml` files to perform the delta.

## Inputs

|INPUT         |Optional|Type     |Default Value|Options|Description|
|--------------|:------:|:-------:|:-----------:|:-----:|:---------:|
|SF_AUTH_URL|N|string|-|-|The Salesforce Auth URL.|
|DELTA_FROM_SOURCE|N|string|-|-|The from source that will be used on the sgd delta.|
|DELTA_TO_SOURCE|N|string|-|-|The to source that will be used on the sgd delta.|
|DRY_RUN|Y|boolean|true|-|Enable or disable the Salesforce project deploy `--dry-run` and `--verbose` flags.|
|TEST_LEVEL|Y|option|RunLocalTests|NoTestRun, RunSpecifiedTests, RunLocalTests, RunAllTestsInOrg|Salesforce project deploy `--test-level` parameter. Defaults to RunLocalTests.|
|TIMEOUT|Y|number|30|-|Salesforce project deploy `--wait` flag value. Timeout in minutes for the command to complete and display results|
|MANIFEST_SOURCE_DIRECTORY|Y|string|force-app|-|Source files path for project manifest generation `--source-dir` flag.|
|MANIFEST_OUTPUT_DIRECTORY|Y|string|manifest|-|Output directoryfor project manifest generation `--output-dir` flag.|
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
          PACKAGE_SOURCE_DIRECTORY: manifest/package.xml
```

