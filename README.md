# GitHub Actions Library

[![license](https://img.shields.io/badge/license-apache-blue.svg)](https://github.com/josh-hogle/gh-actions/blob/trunk/LICENSE)
[![support](https://img.shields.io/badge/support-community-purple.svg)](https://github.com/josh-hogle/gh-actions)
[![Build Image](https://github.com/josh-hogle/gh-actions/workflows/Build%20Image/badge.svg?branch=trunk)](https://github.com/josh-hogle/gh-actions/actions)

<!-- omit in toc -->
## Table of Contents
- [Overview](#overview)
- [build-docker-image](#build-docker-image)
  - [Action Inputs](#action-inputs)
  - [Action Outputs](#action-outputs)
  - [Example](#example)
- [create-release-with-assets](#create-release-with-assets)
  - [Attaching Assets to the Release](#attaching-assets-to-the-release)
  - [Action Inputs](#action-inputs-1)
  - [Action Outputs](#action-outputs-1)
  - [Example](#example-1)
- [pull-docker-image](#pull-docker-image)
  - [Action Inputs](#action-inputs-2)
  - [Action Outputs](#action-outputs-2)
  - [Example](#example-2)
- [push-docker-image](#push-docker-image)
  - [Action Inputs](#action-inputs-3)
  - [Action Outputs](#action-outputs-3)
  - [Example](#example-3)
- [set-conditional-vars](#set-conditional-vars)
  - [Log Message Text](#log-message-text)
  - [File Changes](#file-changes)
  - [Action Inputs](#action-inputs-4)
  - [Action Outputs](#action-outputs-4)
  - [Example](#example-4)
- [set-docker-image-vars](#set-docker-image-vars)
  - [Action Inputs](#action-inputs-5)
  - [Action Outputs](#action-outputs-5)
  - [Example](#example-5)
- [Full Example](#full-example)

## Overview

This repository contains custom GitHub Actions that can be used in workflows when building projects. The following actions are supported:

| Action Name | Description | Details |
|-------------|-------------|---------|
| build-docker-image | Performs the `docker build` step for creating Docker container images | [More info](#build-docker-image) |
| create-release-with-assets | Publishes or updates a GitHub Release and attaches any assets with the release | [More info](#create-release-with-assets) |
| pull-docker-image | Performs a `docker pull` of an existing container image, which can be used to speed up builds of similar containers | [More info](#pull-docker-image) |
| push-docker-image | Performs a `docker tag` and `docker push` for a container image | [More info](#push-docker-image) |
| set-conditional-vars | Used to check log messages and file changes and set variables which can then be used to determine if one or more build steps should occur | [More info](#set-conditional-vars) |
| set-docker-image-vars | Used to pre-configure variables used when building Docker container images | [More info](#set-docker-image-vars) |

Each action is run inside of an Alpine Linux-based container image using PowerShell scripts. The image contains a custom PowerShell module that wraps much of the functionality for the actions into its own reusable functions.

The `image` folder contains the source for this custom Docker image.

[Back to top](#table-of-contents)

----

## build-docker-image

This action is used to perform the `docker build` step of creating and publishing a Docker container image.

### Action Inputs
| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| image-name | The name of the container image itself without any registry or path information (eg: alpine); This value is passed via a build argument and is accessible as `${IMAGE_NAME}` | Yes | N/A |
| base-image | The base image for the container which can be used in any `FROM` directive in the Dockerfile; The value is passed via a build argument and is accessible as `${BASE_IMAGE}` | No | (none) |
| version | The version for the image; The value is passed via a build argument and is accessible as `${VERSION}` | No | (none) |
| release-date | The release date for the image; The value is passed via a build argument and is accessible as `${RELEASE_DATE}` | No | (none) |
| build-context | The build context for the `docker build` command | No | "." |
| dockerfile | The Dockerfile to pass to the `docker build` command | No | "./Dockerfile |
| extra-args | Comma-delimited set of extra arguments to pass to the `docker build` command | No | (none)

### Action Outputs
| Output | Description |
|--------|-------------|
| image-id | The ID of the container image that was built by the action and can be used adding tags in subsequent steps |

### Example

```yaml
- id: build-image
  name: Build Docker image
  if: |
    (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
    ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
    ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
  uses: josh-hogle/gh-actions/build-docker-image@master
  with:
    image-name: ${{ steps.setup-vars.outputs.image-name }}
    base-image: ${{ steps.setup-vars.outputs.base-image }}
    version: ${{ steps.setup-vars.outputs.version }}
    release-date: ${{ steps.setup-vars.outputs.release-date }}
```
[Back to top](#table-of-contents)

----

## create-release-with-assets

This action is used to publish a new GitHub Release or to update an existing release and publish any assets associated with it.

If a release exists with the same release tag, it is updated, otherwise a new release is created. The default release tag is computed by examining the `GITHUB_REF` variable and using anything after the final `/` in the name. For example, if `GITHUB_REF` is `releases/0.5.0` then the default release tag will be `0.5.0`.

An option with this action is to include notes from the CHANGELOG automatically in the release notes. The CHANGELOG must be formatted so that each release is marked by a line starting with `## release-tag` (where `release-tag` is the actual value of the release tag). Any lines that follow are considered to be part of that release's notes up to the next line that marks a new release. This repository's `CHANGELOG.md` file is an example of how this action expects the file to be formatted.

### Attaching Assets to the Release

In order to include assets in a release, you must pass a JSON-formatted string as an action input. The JSON must be an array of assets with each asset being its own object. The object's fields are as follows:

| Property | Description | Required | Default |
|----------|-------------|----------|---------|
| Path | The path to the asset to upload | Yes | N/A |
| MediaType | The MIME type of the file | No | `application/octet-stream` |
| AssetName | The name to give the asset in GitHub; This is the default name of the file that will be used when the asset is downloaded from GitHub | No | The file name portion of `Path` |
| AssetLabel | The display text for the asset in GitHub | No | Same as `AssetName` |

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| access-token | GitHub authentication token used to create/update the release and publish assets | Yes | N/A |
| release-tag | An existing tag to attach the release to or to create if it does not exist | No | (see description above) |
| release-name | The title to use for the release | No | Same as `release-tag` |
| release-notes | Any release notes to add for the release | No | (none) |
| exclude-changelog | If set to true, exclude any notes from the CHANGELOG that match the value of `release-tag` | No | `false` |
| changelog | The path to the CHANGELOG file | No | `CHANGELOG.md` |
| commit-id | The commit ID to use when creating the release tag if it does not already exist | No | The latest commit from the default branch |
| is-draft | If true, mark the release as a draft | No | `false` |
| is-prerelease | If true, mark the release as being pre-release | No | `false` |
| force | If true, update the release if it already exists, otherwise fail the action | No | `true` |
| assets | JSON-formatted list of assets to attach to the release | No | `[]` |

### Action Outputs

| Output | Description |
|--------|-------------|
| release-id | The ID of the newly created relesae or of the existing release that was just updated |
| release-url | The URL of the created/updated release |

### Example

```yaml
- id: create-release
  name: Create GitHub Release
  if: |
    (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
    ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
    ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
  uses: josh-hogle/gh-actions/create-release-with-assets@master
  with:
    access-token: ${{ secrets.GITHUB_TOKEN }}
    release-name: Release ${{ steps.setup-vars.outputs.version }}
    assets: |
        [
            {
                "Path": "mybinary-linux-amd64",
                "MediaType": "application/octet-stream",
                "AssetName": "MyAppBinary-${{ steps.setup-vars.outputs.version }}-linux-amd64"
            },
            {
                "Path": "mybinary-darwin-amd64",
                "AssetName": "MyAppBinary-${{ steps.setup-vars.outputs.version }}-darwin-amd64"
            },
            {
                "Path": "mybinary-win-amd64.exe",
                "MediaType": "application/octet-stream",
                "AssetName": "MyAppBinary-${{ steps.setup-vars.outputs.version }}-win-amd64.exe"
            }
        ]
```
[Back to top](#table-of-contents)

---

## pull-docker-image

This action is used to pull an existing Docker image and cache it in the build environment so the process of building the container can be sped up should there be unchanged layers in the new image. The image can be pulled from any standard Docker registry, including GitHub Container Registry. Google Container Registry is also supported.

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| image | A URL of the form `proto://registry-host/container-path:tag` where `proto` is `docker` for a standard Docker registry, `ghcr` for GitHub Container Registry or `gcr` for Google Container Registry; `registry-host` is the hostname for the registry and `container-path` is any path element for accessing the image along with any `tag` for that image; `tag` defaults to `latest` if it is not specified | Yes | N/A |
| username | If authentication to the registry is required, the username to use when authenticating; ignored for Google Container Registry images | No | (none) |
| password | If authentication to the registry is required, the password to use when authenticating; for Google Container Registry images, this should be a base64-encoded string of the service account JSON key file (see [Google Container Registry authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud-helper)) | No | (none) |


### Action Outputs

There are no outputs for this action.

### Example

```yaml
- id: pull-from-ghcr
  name: Cache existing Docker image from GHCR
  if: |
    (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
    ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
    ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
  uses: josh-hogle/gh-actions/pull-docker-image@master
  with:
    image: ghcr://ghcr.io/josh-hogle/${{ env.PULL_FROM_GHCR }}
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_TOKEN }}
```

[Back to top](#table-of-contents)

---

## push-docker-image

This action is used to tag and push a Docker image to a container registry. The image can be pushed to any standard Docker registry, including GitHub Container Registry. Google Container Registry is also supported.

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| image | The image / image ID produced by the build action which is being tagged and pushed | Yes | N/A
| push-to | A URL of the form `proto://registry-host/container-path` where `proto` is `docker` for a standard Docker registry, `ghcr` for GitHub Container Registry or `gcr` for Google Container Registry; `registry-host` is the hostname for the registry and `container-path` is any path element for accessing the image; do **not** specify tags in the URL | Yes | N/A |
| username | If authentication to the registry is required, the username to use when authenticating; ignored for Google Container Registry images | No | (none) |
| password | If authentication to the registry is required, the password to use when authenticating; for Google Container Registry images, this should be a base64-encoded string of the service account JSON key file (see [Google Container Registry authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud-helper)) | No | (none) |
| tags | A comma-delimited list of tags to push with the image | No | Value of the `GITHUB_SHA` variable

### Action Outputs

There are no outputs for this action.

### Example

```yaml
- id: push-image
  name: Push Docker image to GHCR
  if: |
    (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
    ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
    ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
  uses: josh-hogle/gh-actions/push-docker-image@master
  with:
    image: ${{ steps.build-image.outputs.image }}
    push-to: ghcr://ghcr.io/josh-hogle/${{ env.IMAGE_NAME }}
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_TOKEN }}
    tags: ${{ steps.setup-vars.outputs.tags }}
```

[Back to top](#table-of-contents)

---

## set-conditional-vars

This action can be used to test for certain conditions and set variables based on those conditions. The two key conditions which can be checked are based on the last commit message and/or the files that have changed since the previous commit.

When using this action, it is critical that you use the `fetch-depth` option on the `actions/checkout@v2` action so you retrieve enough history for comparing which files have been changed.

### Log Message Text

The log message condition can be used to detect the presence or absence of a string in the latest commit message. One example use case could be to check for the presence of the string `[skip ci]` so that unnecessary steps in the build process can be skipped. The `log-message` action input is used to configure these test conditions.  It should be a JSON-formatted array containing an object for each test that should be done. Each object must contain the following properties:

| Property | Description | Required | Default |
|----------|-------------|----------|---------|
| verb | Indicates the type of comparison operation being done and must be one of the following operators: `contains`, `doesnotcontain`, `startswith`, `doesnotstartwith`, `endswith`, `doesnotendwith`, `equals` or `doesnotequal` | Yes | N/A |
| text | The text to compare the log message to | Yes | N/A |
| variable | The name of the variable to set if the comparison evaluates to true | Yes | N/A |
| value | The value to set for the variable if the comparison evaluates to true | Yes | N/A |

### File Changes

The changed files condition can be used to detect which files have changed since the previous commit and then set variables which can be used to determine if certain steps of a build need to take place. The `changed-files` action input is used to configure these test conditions. It should be a JSON-formatted array containing an object for each test that should be done. Each object must contain the following properties:

| Property | Description | Required | Default |
|----------|-------------|----------|---------|
| verb | Indicates the type of comparison operation being done and must be one of the following operators: `includes` or `doesnotinclude` | Yes | N/A |
| paths | An array of file names or folders indicating the paths to check; any file (or file within a folder) is used in the comparison against which files have changed since the previous commit | Yes | N/A |
| recurse | If true, include files within any subfolders of folders listed in the `paths` property | No | `false` |
| variable | The name of the variable to set if the comparison evaluates to true | Yes | N/A |
| value | The value to set for the variable if the comparison evaluates to true | Yes | N/A |

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| log-message | JSON-formatted array of objects for log message tests (see above) | No | `[]` |
| changed-files | JSON-formatted array of objects for file change tests (see above) | No | `[]` |

### Action Outputs

This action will set the `value` of the given `variable` property in a comparison object if that comparison evaluates to true. There are no additional outputs that will be set by this action.

### Example

```yaml
- id: set-conditionals
  name: Setup conditional variables
  uses: josh-hogle/gh-actions/set-conditional-vars@0.5.0
  with:
    log-message: |
        [
            {
                "verb": "contains",
                "text": "[skip ci]",
                "variable": "skip_ci",
                "value": "true"
            },
            {
                "verb": "contains",
                "text": "[rebuild]",
                "variable": "rebuild",
                "value": "true"
            }
        ]
    changed-files: |
        [
            {
                "verb": "includes",
                "paths": [ "Dockerfile", "files" ],
                "recurse": true,
                "variable": "code_changed",
                "value": "true"
            }
        ]
```

[Back to top](#table-of-contents)

---

## set-docker-image-vars

This action is used to configure variables that can be used when building Docker images.

The default `version` is computed by examining the `GITHUB_REF` variable and using anything after the final `/` in the name. For example, if `GITHUB_REF` is `releases/0.5.0` then the default version will be `0.5.0`.

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| image-name | The name of the container image without any registry, path or tag information | Yes | N/A |
| base-image | The base image to use for the container | No | (none) |
| version | The version of the container image; If empty, the `GITHUB_REF` environment variable is used to determine the version | No | (see notes above) |
| release-date | The release date of the container in the form DD MMM YYYY | No | The current date |
| extra-tags | Comma-delimited list of extra tags to push with the container image | No | (none) |
| skip-commit-tag | If true, do not automatically include a tag based on the latest commit ID (`GITHUB_SHA` value) | No | `false` |
| skip-version-tag | If true, do not automatically include a tag based on the version | No | `false` |

### Action Outputs

| Output | Description |
|--------|-------------|
| image-name | The name of the image |
| base-image | The base image for the container |
| version | The version to use for the container |
| release-date | The release date to use for the container |
| commit-id | The first 8 characters of the latest commit ID (`GITHUB_SHA` value) |
| tags | Comma-delimited set of tags to push with the image |

### Example

```yaml
- id: setup-vars
  name: Setup build variables
  if: |
    (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
    ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
    ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
  uses: josh-hogle/gh-actions/set-docker-image-vars@master
  with:
    image-name: ${{ env.IMAGE_NAME }}
    base-image: ${{ env.BASE_IMAGE }}
    extra-tags: ${{ env.EXTRA_TAGS }}
```

[Back to top](#table-of-contents)

---

## Full Example

```yaml
name: Build Image

env:
    IMAGE_NAME: alpine
    BASE_IMAGE: alpine:3.12.1
    EXTRA_TAGS: 3.12.1, 3.12, latest
    PULL_FROM_GHCR: alpine:latest
    
on:
    push:
        branches:
        - 'releases/**' # release when pushing a release branch

jobs:
    build:
        name: Build and Push Image
        runs-on: ubuntu-20.04
        steps:
        - id: checkout
          name: Checkout code
          uses: actions/checkout@v2
          with:
            fetch-depth: 2
            
        - id: set-conditionals
          name: Setup conditional variables
          uses: josh-hogle/gh-actions/set-conditional-vars@releases/0.6.0
          with:
            log-message: |
                [
                    {
                        "verb": "contains",
                        "text": "[skip ci]",
                        "variable": "skip_ci",
                        "value": "true"
                    },
                    {
                        "verb": "contains",
                        "text": "[rebuild]",
                        "variable": "rebuild",
                        "value": "true"
                    }
                ]
            changed-files: |
                [
                    {
                        "verb": "includes",
                        "paths": [ "Dockerfile", "files" ],
                        "recurse": true,
                        "variable": "code_changed",
                        "value": "true"
                    }
                ]

        - id: setup-qemu
          name: Set up QEMU
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: docker/setup-qemu-action@v1
        
        - id: setup-buildx
          name: Set up Docker Buildx
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: docker/setup-buildx-action@v1
            
        - id: setup-vars
          name: Setup build variables
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: josh-hogle/gh-actions/set-docker-image-vars@releases/0.6.0
          with:
            image-name: ${{ env.IMAGE_NAME }}
            base-image: ${{ env.BASE_IMAGE }}
            extra-tags: ${{ env.EXTRA_TAGS }}

        - id: pull-from-ghcr
          name: Cache existing Docker image from GHCR
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: josh-hogle/gh-actions/pull-docker-image@releases/0.6.0
          with:
            image: ghcr://ghcr.io/josh-hogle/${{ env.PULL_FROM_GHCR }}
            username: ${{ github.actor }}
            password: ${{ secrets.GHCR_TOKEN }}
                
        - id: build-image
          name: Build Docker image
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: josh-hogle/gh-actions/build-docker-image@releases/0.6.0
          with:
            image-name: ${{ steps.setup-vars.outputs.image-name }}
            base-image: ${{ steps.setup-vars.outputs.base-image }}
            version: ${{ steps.setup-vars.outputs.version }}
            release-date: ${{ steps.setup-vars.outputs.release-date }}

        - id: push-image
          name: Push Docker image to GHCR
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: josh-hogle/gh-actions/push-docker-image@releases/0.6.0
          with:
            image: ${{ steps.build-image.outputs.image-id }}
            push-to: ghcr://ghcr.io/josh-hogle/${{ env.IMAGE_NAME }}
            username: ${{ github.actor }}
            password: ${{ secrets.GHCR_TOKEN }}
            tags: ${{ steps.setup-vars.outputs.tags }}

        - id: create-release
          name: Create GitHub Release
          if: |
            (${{ steps.set-conditionals.outputs.skip_ci != 'true' }} &&
            ${{ steps.set-conditionals.outputs.code_changed == 'true' }}) ||
            ${{ steps.set-conditionals.outputs.rebuild == 'true' }}
          uses: josh-hogle/gh-actions/create-release-with-assets@releases/0.6.0
          with:
            access-token: ${{ secrets.GITHUB_TOKEN }}
            release-name: Release ${{ steps.setup-vars.outputs.version }}
```
