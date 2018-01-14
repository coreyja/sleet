# CircleCI RSpec Status Persistance File Aggregator

## Background and Problem

RSpec has a [feature](https://relishapp.com/rspec/rspec-core/v/3-7/docs/command-line/only-failures) that I find very useful which is the `--only-failures` option. This will re-run only that examples that failed the previous run.

CircleCI has support for [uploading artifcats](https://circleci.com/docs/2.0/artifacts/) with your builds, which allows us to store the persistance file that powers the RSpec only failures option.
However! CircleCI also supports and encourages parallelizing your build, which means even if you upload your rspec persistance file, you actually have a number of them each containing a subset of your test suite.
This is where this tool comes in!

## Purpose

This tool does two things:
1. It downloads all of the `.rspec_failed_examples` files that were uploaded to CircleCI for the most recent build of the current branch
2. It combines the multiple files into a single sorted `.rspec_failed_examples` file, and moves it to the [current directory](https://github.com/coreyja/CRSPFA/issues/1)

## Getting Started

### 1. Configure RSpec to Create and Use an example persistance file

A current limitation is that the RSpec Persistance file must be named `.rspec_example_statuses`.

We need to set the `example_status_persistence_file_path` config in RSpec. Here are the relevant [RSpec docs](https://relishapp.com/rspec/rspec-core/v/3-7/docs/command-line/only-failures#background).

The first step is to create(/or add to) your `spec/spec_helper.rb` file. We want to include the following configuration, which tells RSpec where to store the status persistance file.

```
RSpec.configure do |c|
  c.example_status_persistence_file_path = ".rspec_example_statuses"
end
```

if you just created the `spec_helper.rb` file then you will need to create a `.rspec` file containing the following to load your new helper file

```
--require spec_helper
```

### 2. Collect the example persistance files in CircleCI

To do this we need to create a step which [saves](https://circleci.com/docs/2.0/artifacts/) the `.rspec_example_statuses` as artifacts of the build. The following is an example of such a step in CircleCI. This must happen after rspec has run or else the persistance file will not exist.

```
- store_artifacts:
    path: ~/PROJECT_NAME/.rspec_example_statuses

```

### 3. Run this tool in the root of your project

```
sleet
```

This will look up the latest completed build in CircleCI for this branch, and download all the relevant `.rspec_example_statuses` files. It then combines and sorts them and saves the result to the `.rspec_example_statuses` file locally.

### 4. Run RSpec with `--only-failures`

```
bundle exec rspec --only-failures
```

This will run only the examples that failed in CircleCI!
