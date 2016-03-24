# Branching Guidelines

## Permanent Branches

There are two permanent branches, `development` and `master`.

- Each commit to `master` is a new release, and should be tagged with the version (e.g. `git tag v2.1.0`). `master` should never be committed to for development work, and should only be branched from for hot-fixes (see below).

- `development` will always contain completed features, and should always be test-ready code.

## Temporary Branches

There are three types of temporary branch: feature, release and hot-fix.

- Feature branches are for working on a single addition or change, such as a new feature. They should **always** be branched from `development` and merged back into `development`. The names of these branches should be lower case and use dashes for spaces (e.g. `add-contacts-page`).

- Release branches should be pulled from `development` when a release is to be made, _after_ a set of features have been merged into `development`. These short-lived branches should be named as `release-{version name}`, and are only to be used for preparing the app for release (bumping build numbers, committing ProGuard mappings, etc.). When the app is ready to be released, these should be merged into `master` and `development`, and then deleted.

- Hot-fix branches should be pulled from `master` when an urgent bug needs to be fixed in an existing release. Branches should be named as `hot-fix-bug-summary`. Once the code is patched, it should be merged back into `master` (as a new release) and into `development`, then deleted.

## Branch Processes

### Feature Branch Process

1. Checkout `development` and pull the latest version.
  1. `git checkout development`
  2. `git pull`

2. Create and checkout a feature branch, such as `my-feature-branch`.
  1. `git checkout -b my-feature-branch`

3. Build the feature, committing to the feature branch as appropriate.

4. When complete, merge the feature back onto `development`.
  1. `git checkout development`
  2. `git pull`
  3. `git merge --no-ff my-feature-branch`
  4. `git branch -d my-feature-branch`
  5. `git push origin development`

### Release Process

1. Checkout `development` and pull the latest version.
  1. `git checkout development`
  2. `git pull`

2. Create and checkout a release branch, such as `release-2.1.0`.
  1. `git checkout -b release-2.1.0`

3. Update the release notes, build numbers, ProGuard files, etc.

4. Commit the changes made to the code.
  1. `git commit -a -m "Prepare release v2.1.0"`

5. When complete, merge the release into `master`, then into `development`.
  1. `git checkout master`
  2. `git pull`
  3. `git merge --no-ff release-2.1.0`
  4. `git tag v2.1.0`
  5. `git checkout development`
  6. `git pull`
  7. `git merge --no-ff release-2.1.0`
  8. `git branch -d release-2.1.0`

### Hot-fix Process

1. Checkout `master` and pull the latest version.
  1. `git checkout master`
  2. `git pull`

2. Create and checkout a hot-fix branch, such as `hot-fix-bug-summary`.
  1. `git checkout -b hot-fix-bug-summary`

3. Fix the bug, committing to the hot-fix branch as appropriate.

4. Follow step #3 of the release process.

5. When complete, merge the code back into `master`, then into `development`.
  1. `git checkout master`
  2. `git pull`
  3. `git merge --no-ff hot-fix-bug-summary`
  4. `git checkout development`
  5. `git pull`
  6. `git merge --no-ff hot-fix-bug-summary`
  7. `git branch -d hot-fix-bug-summary`