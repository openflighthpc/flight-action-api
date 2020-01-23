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

# Sinja has a weird "feature" (bug?) where it can not serialize Hash objects
# tl;dr Sinja thinks the Hash is the options to the serializer NOT the model
# Using a decorator design pattern for the models is a work around
class BaseHashieDashModel
  def self.inherited(klass)
    data_class = Class.new(Hashie::Dash) do
      include Hashie::Extensions::IgnoreUndeclared
      include ActiveModel::Validations

      def self.method_added(m)
        parent.delegate(m, to: :data)
      end
    end

    klass.const_set('DataHash', data_class)
    klass.delegate(*(ActiveModel::Validations.instance_methods - Object.methods), to: :data)
  end

  attr_reader :data

  def initialize(*a)
    @data = self.class::DataHash.new(*a)
  end
end

class Node < BaseHashieDashModel
  DataHash.class_exec do
    include Hashie::Extensions::Dash::PropertyTranslation

    property :name,   required: true
    property :params, required: true
    property :ranks,  default: [], transform_with: ->(v) { (v.dup << 'default').uniq }
  end
end

class Group < BaseHashieDashModel
  DataHash.class_exec do
    property  :name,  required: true
    property  :nodes, default: []
  end
end

class Command < BaseHashieDashModel
  DataHash.class_exec do
    include Hashie::Extensions::Dash::PropertyTranslation

    property :name
    property :summary
    property :description,  from: :summary
    property :scripts,      default: {}

    validates :name,        presence: true, format: {
      with: /\A[^_]*\Z/,    message: 'must not contain underscores'
    }
    validates :summary,     presence: true
    validates :description, presence: true

    validate :validate_has_a_default_script
    validate :validate_scripts_are_valid
    validate :validate_scripts_have_matching_ranks

    def lookup_script(*ranks)
      scripts[(ranks & scripts.keys).first || 'default']
    end

    private

    def validate_scripts_have_matching_ranks
      return unless scripts.is_a?(Hash)
      scripts.each do |rank, script|
        if script.is_a?(Script) && script.rank == rank
          # noop
        elsif script.is_a?(Script)
          errors.add(:"#{rank}_script",
                     "does not match its script's rank: #{script.rank}")
        else
          errors.add(:"#{rank}_script", 'is not a Script object')
        end
      end
    end

    def validate_scripts_are_valid
      return unless scripts.is_a?(Hash)
      scripts.select { |_, s| s.respond_to?(:valid?) }
             .reject { |_, s| s.valid? }
             .each do |name, script|
        errors.add(:"#{name}_script", script.errors.full_messages.join(','))
      end
    end

    def validate_has_a_default_script
      return if scripts.is_a?(Hash) && scripts['default']
      errors.add(:scripts, 'does not contain the default script')
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

    validate :validate_variables_are_not_empty

    private

    def validate_variables_are_not_empty
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
      self.status = code.to_i
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

