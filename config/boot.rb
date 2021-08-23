# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
#
# This file is part of Flight Action API.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Action API is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Action API. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Action API, please visit:
# https://github.com/openflighthpc/flight-action-api
#===============================================================================


ENV['RACK_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'rubygems'
require 'bundler'

if ENV['RACK_ENV'] == 'development'
  Bundler.require(:default, :development)
else
  Bundler.require(:default)
end

# Shared activesupport libraries
require 'active_support/core_ext/hash/keys'

# Ensure ApplicationModel::ValidationError is defined in advance
require 'active_model/validations.rb'

lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# NOTE: The following LOAD_PATH modification is non-idiomatic but required for legacy support
root = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(root) unless $LOAD_PATH.include?(root)

require 'flight_action_api'
require 'config/initializers/figaro'
require 'config/initializers/logger'

# Ensures the shared secret exists
FlightJobScriptAPI.config.auth_decoder

require 'app/errors'
require 'app/models'
require 'app/models/command'
require 'app/models/ticket'
require 'config/initializers/facades'
require 'app/token'
require 'app/serializers'
require 'app'
