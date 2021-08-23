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

require 'flight'
require 'flight_configuration'

module FlightActionApi
  class ConfigError < StandardError; end

  class Configuration
    include FlightConfiguration::DSL
    # NOTE: Does not support ActiveModel version 5
    # include FlightConfiguration::RichActiveValidationErrorMessage
    include ActiveModel::Validations

    root_path File.expand_path("../..", __dir__)
    application_name 'action-api'

    # Disable the user config files
    def self.user_config_files; []; end

    attribute :command_directory_path, default: 'libexec',
              transform: relative_to(root_path)
    attribute :nodes_config_path, default: 'config/nodes.yaml',
              transform: relative_to(root_path)
    attribute :log_level, default: 'warn'
    attribute :job_threads, default: 4
    # NOTE: action-api intentionally does not use the generic 'etc/shared-secret.conf'
    #       As it is not formally part of the web-suite. It can however be re-configured
    #       to use this path
    attribute :shared_secret_path, default: 'etc/action-api/shared-secret.conf',
              transform: relative_to(root_path)
    attribute :working_directory_path, default: 'libexec',
              transform: relative_to(root_path)

    validate do
      # Skip the validation if shared_secret_path exists
      if File.exists? shared_secret_path
        Flight.logger.warn <<~WARN if ENV['jwt_secret']
          The configuration mechanism for flight-action-api has changed!
          The JWT shared secret is now stored within:
          #{shared_secret_path}

          The legacy 'jwt_secret' environment variable is now being ignored.
          Unsetting the env-var will suppress this warning.
        WARN
        next
      end

      # Attempt to generate the shared secret from the legacy env-var
      secret = if ENV['jwt_secret']
        Flight.logger.warn <<~WARN.chomp
          Attempting to generate the shared secret config from the 'jwt_secret' env var
        WARN
        ENV['jwt_secret']
      else
        SecureRandom.alphanumeric(50)
      end

      begin
        FileUtils.mkdir_p File.dirname(shared_secret_path)
        File.write shared_secret_path, secret, perm: 0440, mode: 'w'
      rescue
        __logs__.error("Failed to generate: #{shared_secret_path}")
        __logs__.error($!)
        errors.add(:shared_secret_path, "could not be generated")
      end
      __logs__.warn("Generated the shared secret config: #{shared_secret_path}")
      if ENV['jwt_secret']
        __logs__.warn("The 'jwt_secret' environment variable is now obsolete and can be unset")
      end
    end

    def jwt_secret
      @jwt_secret ||= File.read shared_secret_path
    end
  end
end
