# RuboCop Cop for Elegant Ruby Code

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/rubocop-elegant)](https://www.rultor.com/p/yegor256/rubocop-elegant)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/rubocop-elegant/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/rubocop-elegant/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/rubocop-elegant.svg)](https://badge.fury.io/rb/rubocop-elegant)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/yegor256/rubocop-elegant/master/frames)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/rubocop-elegant/blob/master/LICENSE.txt)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/rubocop-elegant.svg)](https://codecov.io/github/yegor256/rubocop-elegant?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/rubocop-elegant)](https://hitsofcode.com/view/github/yegor256/rubocop-elegant)

This is a [RuboCop] plugin that enforces
  [Elegant Objects] principles in Ruby code.
Default RuboCop configuration is too permissive, allowing coding practices
  that lead to unmaintainable code: comments that lie, verbose methods,
  cryptic variable names, and so on.
This plugin configures existing RuboCop cops with stricter settings
  and adds custom cops for rules that RuboCop doesn't provide out of the box.

First, install it:

```bash
gem install rubocop-elegant
```

Then, add it to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-elegant
```

Should work.

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

[RuboCop]: https://rubocop.org/
[Elegant Objects]: https://www.elegantobjects.org/
