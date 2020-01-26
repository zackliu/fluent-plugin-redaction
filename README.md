# Redaction filter plugin for Fluentd

[![Build Status](https://travis-ci.org/oleewere/fluent-plugin-redaction.svg?branch=master)](https://travis-ci.org/oleewere/fluent-plugin-redaction)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-redaction.svg)](http://badge.fury.io/rb/fluent-plugin-redaction)
![](https://ruby-gem-downloads-badge.herokuapp.com/fluent-plugin-redaction?type=total&metric=true)

## Requirements

| fluent-plugin-redaction | fluentd | ruby |
|------------------------|---------|------|
| >= 0.1.0 | >= v0.14.0 | >= 2.4 |

## Overview

Redaction filter plugin that is used to redact/anonymize data in specific record fields.

## Installation

Install from RubyGems:
```
$ gem install fluent-plugin-redaction
```

## Configuration

```
  <filter **>
    @type redaction
    <rule>
      key message
      value myemail@mail.com
      replace ****@mail.com
    </rule>
    <rule>
      key message
      value mycardnumber
    </rule>
    <rule>
      key message
      pattern /my_regex_pattern/
      replace [REDACTED]
    </rule>
  </filter>
```

### Configuration options

#### key

Specified field in a record. Replacement will happen against the value of the selected field.

#### value

Specific value that is searched in the value of the selected field. Replace matches with `replace` value.

#### pattern

Regular expression, on matches in the specified record field data will be replaced with the value of `replace` field.

#### replace

The replacement string on value/pattern matches. Default value: `[REDACTED]`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
