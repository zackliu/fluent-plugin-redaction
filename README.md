# Redaction filter plugin for Fluentd

![Build](https://github.com/oleewere/fluent-plugin-redaction/actions/workflows/build.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-redaction.svg)](http://badge.fury.io/rb/fluent-plugin-redaction)
![](https://ruby-gem-downloads-badge.herokuapp.com/fluent-plugin-redaction?type=total&metric=true)

## Requirements

| fluent-plugin-redaction | fluentd | ruby |
|------------------------|---------|------|
| >= 0.1.0 | >= v0.14.0 | >= 2.4 |

## Overview

Redaction filter plugin that is used to redact/anonymize data in specific record fields.

## Build from source

```
bundle exec rake build
```

## Tests

```
bundle exec rake test
```

## Installation

Install from RubyGems:
```
$ gem install fluent-plugin-redaction-alt
```

## Configuration

```
  <filter **>
    @type redaction_alt
    rule_file my_rule_file
  </filter>
```

And the `my_rule_file` should be

```
<rule>
  key message
  pattern /hell/
</rule>

<rule>
  key replaceMessage
  pattern /hell/
  replace *****
</rule>
```
