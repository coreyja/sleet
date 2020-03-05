# Sleet ☁️ ❄️

[![Gem Version](https://badge.fury.io/rb/sleet.svg)](https://badge.fury.io/rb/sleet)
[![Maintainability](https://api.codeclimate.com/v1/badges/7f346b368d72b53ef630/maintainability)](https://codeclimate.com/github/coreyja/sleet/maintainability)
[![CircleCI](https://circleci.com/gh/coreyja/sleet.svg?style=svg)](https://circleci.com/gh/coreyja/sleet)
[![Join the chat at https://gitter.im/rspec-sleet/community](https://badges.gitter.im/rspec-sleet/community.svg)](https://gitter.im/rspec-sleet/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Background and Problem

RSpec has a [feature](https://relishapp.com/rspec/rspec-core/v/3-7/docs/command-line/only-failures) that I find very useful which is the `--only-failures` option. This will re-run only that examples that failed the previous run.

CircleCI has support for [uploading artifacts](https://circleci.com/docs/2.0/artifacts/) with your builds, which allows us to store the persistance file that powers the RSpec only failures option.
However! CircleCI also supports and encourages parallelizing your build, which means even if you upload your rspec persistance file, you actually have a number of them each containing a subset of your test suite.
This is where `Sleet` comes in!

## Purpose

This tool does two things:
1. It downloads all of the `.rspec_failed_examples` files that were uploaded to CircleCI for the most recent build of the current branch
2. It combines the multiple files into a single sorted `.rspec_failed_examples` file, and moves it to the [current directory](https://github.com/coreyja/CRSPFA/issues/1)

## Getting Started

### 1. Configure RSpec to Create and Use an example persistance file

We need to set the `example_status_persistence_file_path` config in RSpec. Here are the relevant [RSpec docs](https://relishapp.com/rspec/rspec-core/v/3-7/docs/command-line/only-failures#background).

The first step is to create(/or add to) your `spec/spec_helper.rb` file. We want to include the following configuration, which tells RSpec where to store the status persistance file. The actual location and file name are up to you, this is just an example. (Though using this name will require less configuration later.)

```
RSpec.configure do |c|
  c.example_status_persistence_file_path = ".rspec_example_statuses"
end
```

if you just created the `spec_helper.rb` file then you will need to create a `.rspec` file containing the following to load your new helper file.

```
--require spec_helper
```

Again there are other ways to load your `spec_helper.rb` file, including requiring it from each spec. Pick one that works for you.

### 2. Collect the example persistance files in CircleCI

To do this we need to create a step which [saves](https://circleci.com/docs/2.0/artifacts/) the `.rspec_example_statuses` as artifacts of the build. The following is an example of such a step in CircleCI. This must happen after rspec has run or else the persistance file will not exist.

```
- store_artifacts:
    path: .rspec_example_statuses

```

### 3. Save a CircleCI Token locally (to access private builds)

In order to see private builds/repos in CircleCI you will need to get a CircleCI token and save it locally to a Sleet Configuration file.
The recommended approach is to create a yml file in your home directory which contains your the key `circle_ci_token`

```
circle_ci_token: PLACE_TOKEN_HERE
```

An API token can be generated here: [https://circleci.com/account/api](https://circleci.com/account/api)

### 4. Run this tool from your project

```
sleet
```

This will look up the latest completed build in CircleCI for this branch, and download all the relevant `.rspec_example_statuses` files. It then combines and sorts them and saves the result to the `.rspec_example_statuses` file locally.

### 5. Run RSpec with `--only-failures`

```
bundle exec rspec --only-failures
```

This will run only the examples that failed in CircleCI!

## Configuration

If you are using Worklfows in your CircleCI builds, or you are working with a different persistance file name, you may need to configure Sleet beyond the defaults.

Sleet currently supports two ways to input configurations:

1. Through YML files
    - `Sleet` will search 'up' from where the command was run and look for `.sleet.yml` files. It will combine all the files it finds, such that 'deeper' files take presedence. This allows you to have a user-level config at `~/.sleet.yml` and have project specific files which take presendence over the user level config (ex: `~/Projects/foo/.sleet.yml`)
2. Through the CLI
    - These always take presendece the options provided in the YML files

To view your current configuration use the `sleet config` command which will give you a table of the current configuration. You can also use the `--print-config` flag with the `fetch` command to print out the config, including any other CLI options. This can be useful for bebugging as the output also tells you where each option came from.

### Options

These are the options that are currently supported

#### `source_dir`

Alias: s

This is the directory of the source git repo. If a `source_dir` is NOT given we look up from the current directory for the nearest git repo.

#### `input_file`

Alias: i

This is the name of the Rspec Circle Persistance File in CircleCI. The default is `.rspec_example_statuses`

This will match if the full path on CircleCI ends in the given name.

#### `output_file`

Alias: o

This is the name for the output file, on your local system. It is relative to the `source_dir`.

Will be IGNORED if `workflows` is provided.

#### `workflows`

Alias: w

If you are using workflows in CircleCI, then this is for you! You need to tell `Sleet` which build(s) to look in, and where each output should be saved.
The input is a hash, where the key is the build name and the value is the `output_file` for that build. Sleet supports saving the artifacts to multiple builds, meaning it can support a mono-repo setup.

Build-Test-Deploy Demo:

For this example you have three jobs in your CircleCI Workflow, `build`, `test` and `deploy`, but only 1 (the `test` build) generate an Rspec persistance file

This command will pick the `test` build and save its artifacts to the `.rspec_example_statuses` file

```
sleet fetch --workflows test:.rspec_example_statuses
```

MonoRepo Demo:

If you have a mono-repo that contains 3 sub-dirs. `foo`, `bar` and `baz`. And each one has an accompanying build. We can process all these sub-dirs at once with the following workflow command.

```
sleet fetch --workflows foo-test:foo/.rpsec_example_statuses bar-test:bar/.rspec_example_statuses baz-specs:baz/spec/examples.txt
```
