# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of Action Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Action Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Action Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Action Server, please visit:
# https://github.com/openflighthpc/action-server
#===============================================================================

# Loads the configurations into the environment
Figaro.application = Figaro::Application.new(
  environment: (ENV['RACK_ENV'] || 'development').to_sym,
  path: File.expand_path('../application.yaml', __dir__)
)
Figaro.load
      .reject { |_, v| v.nil? }
      .each { |key, value| ENV[key] ||= value.to_s }

# Hard sets the app's root directory to the current code base
ENV['app_root_dir'] = File.expand_path('../..', __dir__)
root_dir = ENV['app_root_dir']

# Enforce the requirements for Full Upstream Mode
ENV['full_upstream'] = nil unless Figaro.env.full_upstream == 'true'
Figaro.require_keys('remote_url') if Figaro.env.full_upstream

# Enforce the requirements for Partial Upstream Mode
# NOTE: This is an requirement for Full Upstream and most be done after the fact
Figaro.require_keys('remote_cluster', 'remote_jwt') if Figaro.env.remote_url

# Enforce the generally required keys
relative_keys = ['nodes_config_path',
                 'command_directory_path',
                 'working_directory_path']
Figaro.require_keys(*['jwt_shared_secret', 'log_level', *relative_keys])

# Sets relative keys from the install directory
# NOTE: Does not affect the path if it is already absolute
relative_keys.each { |k| ENV[k] = File.absolute_path(ENV[k], root_dir) }

