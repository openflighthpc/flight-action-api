# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
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

require 'securerandom'
require 'open3'

class Script < BaseHashieDashModel
  DataHash.class_exec do
    include Hashie::Extensions::Dash::PropertyTranslation
    include Hashie::Extensions::Dash::Coercion

    property :rank
    property :path,  coerce: String

    validates :rank,  presence: true
    validates :path,  presence: true
  end
end

class Ticket < BaseHashieDashModel
  DataHash.class_exec do
    property :id, default: ->() { SecureRandom.hex(20) }
    property :context
    property :command
    property :arguments, default: []
    property :jobs

    validates :context,  presence: true
    validates :command,  presence: true

    def nodes
      if context.is_a?(Node)
        [context]
      elsif context.is_a?(Group)
        context.nodes
      else
        []
      end
    end

    def generate_and_run
      DEFAULT_LOGGER.info "Starting Ticket: #{self.id}"
      self.jobs = nodes.map { |n| Job.new(node: n, ticket: self) }
      self.jobs.each do |job|
        DEFAULT_LOGGER.info "Add Job \"#{job.node.name}\": #{job.id}"
      end
      self.jobs.each(&:run)
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

    def run
      cwd = Figaro.env.working_directory_path!
      script_root = Figaro.env.command_directory_path
      script = ticket.command.lookup_script(*node.ranks)
      envs = node.params
        .tap { |e| e['name'] = node.name }
        .tap { |e| e['command'] = ticket.command.name }
        .tap { |e| e['SCRIPT_ROOT'] = script_root }
        .stringify_keys
      DEFAULT_LOGGER.info <<~INFO

        # Job Definition ===============================================================
        # Ticket: #{ticket.id}
        # ID:     #{id}
        # Node:   #{node.name}
        # Rank:   #{script.rank}
        # Script: #{script.path}
        # Args:   #{ticket.arguments}
        # Working Directory: #{cwd}
        # Environment Variables:
        #{envs.map { |k, v| "#{k}=#{v}" }.join("\n")}
      INFO
      DEFAULT_LOGGER.info "Starting Job: #{self.id}"
      out, err, code = Open3.capture3(envs, script.path, *ticket.arguments, chdir: cwd)
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
