[![Build Status](https://travis-ci.org/openflighthpc/flight-action-api.svg?branch=master)](https://travis-ci.org/openflighthpc/flight-action-api)

# Flight Action API

Define easily configurable commands that can be preformed over a single or group of nodes.

## Installation

### Preconditions

The following are required to run this application:

* OS:           Centos7
* Ruby:         2.5+
* Yum Packages: gcc, make

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems. This guide assumes the `bin` directory is on your `PATH`. If you prefer not to modify your `PATH`, then some of the commands need to be prefixed with `/path/to/app/bin`.

```
git clone https://github.com/openflighthpc/flight-action-api
cd flight-action-api

# Add the binaries to your path, which will be used by the remainder of this guide
export PATH=$PATH:$(pwd)/bin
bundle install --without development test --path vendor

# The following command can be ran without modifying the PATH variable by
# prefixing `bin/` to the commands
bin/bundle install --without development test pry --path vendor
```

### Configuration

This application can be configured by setting the configuration values into the environment. Refer to the configuration [reference](config/application.yaml.reference) and [defaults](config/application.yaml) for an exhaustive list.

Regardless of the following mode selection, the `jwt_secret` must be exported into the environment. This will be used to generate and validate the authorization tokens and must be kept private.

```
export jwt_secret=<keep-this-secret-safe>
```

The default modes the application ships with is `standalone` nodes and `exploding` groups. They are responsible for the following:
* `standalone`: read the available `nodes` from the node config,
* `exploding`: expand group names into a list of nodes

There also needs to be a predefined set of `commands` available to be ran.

*NOTE*: For System Administrators and Integrators
Please refer to the [additional documentation](docs/ticket-lifecycle.md) on how the application processes tickets. This covers the advanced functioning of the application and security implications. It also gives context to the various configuration options.

#### Commands Config

The `commands` are configured by creating sub directories of the `command_directory_path` directory.  A valid command directory contains a `metadata.yaml` file and an executable `default.sh` script.

A sample command is provided in this repository:

```
$ ls libexec-dev/sample
default.sh  metadata.yaml  metal.sh
$ cat libexec-dev/sample/metadata.yaml
help:
  summary: 'sample action'
  description: >
    A sample action to serve as a simple example of how to create commands and
    scripts.
$ cat libexec-dev/sample/default.sh 
#!/bin/bash
echo "Running the default script for: $name"
echo Done
$ cat libexec-dev/sample/metal.sh 
#!/bin/bash
echo "Running the metal script for: $name"
echo Doing metal stuff ....
echo Done
```

The `help` section in metadata.yaml is required as it is used by client-side to generate help pages. The required `summary` should be a single line summary of the command, where the optional description maybe longer.

In additional to the `default.sh` script, other scripts can optionally be defined for other ranks.  The script selected for executation is based on the available scripts and the ranks for the current node.

#### Standalone Nodes

When the `nodes` are in `standalone` mode, they are read from a static YAML file with the following structure. See the [example nodes config](config/nodes.example.yaml) for the version which is used when running in the `development` environment.

```
<node-name>:
  ranks: [rank1, rank2, ...]
  key1: value1
  key2: value2
  ....
...
```

The `ranks` key is optional and maybe either a single string or an array of them. This alters the `script` lookup order against the `command` according to the `ranks` mechanism.

All other keys are considered `parameters` to the `node` and are available to the `variables` mechanism.

#### Exploding Nodes

This mode enables `group` support by performing name expansion on the name. No specific configuration is required for this `mode`. Refer to the [routes documentation](docs/routes.md) for further details.

#### Partial Upstream Mode

Not Supported

#### Full Upstream Mode

Not Supported

### Integrating with systemd and OpenFlightHPC/FlightRunway

The [provided systemd unit file](support/flight-action-api.service) has been designed to integrate with the `OpenFlightHPC` [flight-runway](https://github.com/openflighthpc/flight-runway) package. The following preconditions must be satisfied for the unit file to work:
1. `OpenFlightHPC` `flight-runway` must be installed,
2. The server must be installed within `/opt/flight/opt/flight-action-api`,
3. The log directory must exist: `/opt/flight/var/log`, and
4. The configuration file must exist: `/opt/flight/etc/flight-action-api.conf`.

The configuration file will be loaded into the environment by `systemd` and can be used to override values within `config/application.yaml`. This is the recommended way to set the custom configuration values and provides the following benefits:
1. The config will be preserved on update,
2. It keeps the secret keys separate from the code base, and
3. It eliminates the need to source a `bashrc` in order to setup the environment.

## Starting the Server

The `puma` server daemon can be started manually with:

```
bin/puma -p <port> -e production -d \
          --redirect-append \
          --redirect-stdout <stdout-log-file-path> \
          --redirect-stderr <stderr-log-file-path> \
          --pidfile         <pid-file-path>
```

## Stopping the Server

The `pumactl` command can be used to preform various start/stop/restart actions on the puma server. Assuming that `systemd` hasn't been setup, the following will stop the server:

```
bin/pumactl stop
```

## Authentication

The API requires all requests to carry with a [jwt](https://jwt.io). All tokens have permission to view and execute the `commands`.

The following `rake` tasks are used to generate tokens with 30 days expiry. Tokens from other sources will be accepted as long as they:
1. Where signed with the same shared secret,
2. An [expiry claim](https://tools.ietf.org/html/rfc7519#section-4.1.4) has been made.

As the shared secret is environment dependant, the `RACK_ENV` must be set within your environment.

```
# Set the rack environment
export RACK_ENV=production

# Generate a user token
rake token:user       # Valid for 30 days [Default]
rake token:user[360]  # Valid for 360 days
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

Flight Action API is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.
