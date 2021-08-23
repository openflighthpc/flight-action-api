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
    LEGACY_CONFIG = File.expand_path("../../config/application.yaml", __dir__)

    include FlightConfiguration::DSL
    # NOTE: Does not support ActiveModel version 5
    # include FlightConfiguration::RichActiveValidationErrorMessage
    include ActiveModel::Validations

    root_path File.expand_path("../..", __dir__)
    application_name 'action-api'

    # Load configs from the legacy file
    config_files.tap { |c| c.unshift LEGACY_CONFIG }

    # Disable the user config files
    def self.user_config_files; []; end

    # Log the legacy config warning on build
    def self.build(*_)
      super.tap do |c|
        next unless File.exists? LEGACY_CONFIG
        c.__logs__.warn <<~WARN
          The default configuration path has changed!
          The legacy config will be removed in a future release.

          Please migrate your configs from:
          #{LEGACY_CONFIG}

          To the new config path:
          #{config_files.first}
        WARN
      end
    end

    attribute :bind_address, default: 'tcp://127.0.0.1:917'
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
      next if File.exists? shared_secret_path

      # Attempt to generate a shared secret when required
      begin
        FileUtils.mkdir_p File.dirname(shared_secret_path)
        secret = SecureRandom.alphanumeric(50)
        File.write shared_secret_path, secret, perm: 0440, mode: 'w'
        __logs__.warn("Generated the shared secret config: #{shared_secret_path}")
      rescue
        __logs__.error("Failed to generate: #{shared_secret_path}")
        __logs__.error($!)
        errors.add(:shared_secret_path, "could not be generated")
      end
    end

    def jwt_secret
      @jwt_secret ||= File.read shared_secret_path
    end
  end
end
