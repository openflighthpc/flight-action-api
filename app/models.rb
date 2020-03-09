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

require 'securerandom'
require 'open3'

class Command < BaseHashieDashModel
  DataHash.class_exec do
    include Hashie::Extensions::Dash::PropertyTranslation

    CMD_NAME_REGEX = /\A[^_]*\Z/
    CMD_NAME_MESSAGE = 'must not contain underscores'

    property :name
    property :summary
    property :description,  from: :summary
    property :scripts,      default: {}
    # property :aliases,      default: [],  transform_with: ->(v) { Array.wrap(v) }

    validates :name,        presence: true, format: {
      with: CMD_NAME_REGEX,    message: CMD_NAME_MESSAGE
    }
    validates :summary,     presence: true
    validates :description, presence: true

    # Ensures the scripts hash's keys match the rank stored within each script
    validate do
      next unless scripts.is_a?(Hash)
      scripts.each do |rank, script|
        if script.is_a?(Script) && script.rank == rank
          # noop
        elsif script.is_a?(Script)
          errors.add(:"#{rank}_script", "does not match its script's rank: #{script.rank}")
        else
          errors.add(:"#{rank}_script", 'is not a Script object')
        end
      end
    end

    # Ensures each script is valid
    validate do
      next unless scripts.is_a?(Hash)
      scripts.select { |_, s| s.respond_to?(:valid?) }
             .reject { |_, s| s.valid? }
             .each do |name, script|
        errors.add(:"#{name}_script", script.errors.full_messages.join(','))
      end
    end

    # Ensures there is a default script
    validate do
      next if scripts.is_a?(Hash) && scripts['default']
      errors.add(:scripts, 'does not contain the default script')
    end

    def lookup_script(*ranks)
      scripts[(ranks & scripts.keys).first || 'default']
    end
  end
end

class Script < BaseHashieDashModel
  DataHash.class_exec do
    include Hashie::Extensions::Dash::PropertyTranslation
    include Hashie::Extensions::Dash::Coercion

    property :rank
    property :body,       coerce: String
    property :variables,  default: [], transform_with: ->(v) { Array.wrap(v).map(&:to_s) }

    validates :rank,  presence: true
    validates :body,  presence: true

    validate do
      errors.add(:variables, "must not contain empty string") if variables.include?('')
    end
  end
end

class Ticket < BaseHashieDashModel
  DataHash.class_exec do
    property :id, default: ->() { SecureRandom.hex(20) }
    property :context
    property :command
    property :jobs

    property :run_when_serialized, default: false

    def nodes
      if context.is_a?(Node)
        [context]
      elsif context.is_a?(Group)
        context.nodes
      else
        []
      end
    end

    def generate_and_run!
      DEFAULT_LOGGER.info "Starting Ticket: #{self.id}"
      self.jobs = if command
        nodes.map { |n| Job.new(node: n, ticket: self) }
      else
        DEFAULT_LOGGER.error <<~ERROR.squish
          Ticket '#{self.id}' does not have a command! This is likely a client error.
          Continuing without adding any jobs.
        ERROR
        []
      end
      self.jobs.each do |job|
        DEFAULT_LOGGER.info "Add Job \"#{job.node.name}\": #{job.id}"
      end
      self.jobs.each(&:run!)
    ensure
      DEFAULT_LOGGER.info "Finished Ticket: #{self.id}"
    end
  end
end

class Job < BaseHashieDashModel
  DataHash.class_exec do
    property :id, default: ->() { SecureRandom.hex(20) }
    property :node
    property :ticket
    property :stdout
    property :stderr
    property :status

    def run!
      cwd = Figaro.env.working_directory_path!
      script = ticket.command.lookup_script(*node.ranks)
      envs = script.variables
                   .map { |v| [v, node.params[v.to_sym]] }
                   .to_h
                   .tap { |e| e['name'] = node.name }
      DEFAULT_LOGGER.info <<~INFO

        # Job Definition ===============================================================
        # Ticket: #{ticket.id}
        # ID:     #{id}
        # Node:   #{node.name}
        # Rank:   #{script.rank}
        # Working Directory:
        cd #{cwd}
        # Environment Variables:
        #{envs.map { |k, v| "#{k}=#{v}" }.join("\n")}

        # Execute Script:
        #{script.body}
        # End Job Definition ===========================================================
        # NOTE: This definition is not literally executed. See documentation for details
      INFO
      DEFAULT_LOGGER.info "Starting Job: #{self.id}"
      out, err, code = Open3.capture3(envs, script.body, chdir: cwd)
      self.stdout = out
      self.stderr = err
      self.status = code.exitstatus
      DEFAULT_LOGGER.info <<~INFO

        # Job Results ==================================================================
        # Ticket: #{ticket.id}
        # ID:     #{id}
        # Status: #{self.status}
        # STDOUT:
        #{self.stdout}

        # STDERR:
        #{self.stderr}
        # End Job Results ==============================================================
      INFO
    ensure
      DEFAULT_LOGGER.info "Finished Job: #{self.id}"
    end
  end
end

