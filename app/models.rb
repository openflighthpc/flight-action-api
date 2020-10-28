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

class Job < BaseHashieDashModel
  attr_reader :read_pipe

  def initialize(hash={})
    super
    @read_pipe, @write_pipe = IO.pipe
  end

  DataHash.class_exec do
    property :id, default: ->() { SecureRandom.hex(20) }
    property :node
    property :ticket
    property :stdout, default: ""
    property :stderr, default: ""
    property :status
  end

  def run
    DEFAULT_LOGGER.info "Running Job: #{self.id}"
    cwd = Figaro.env.working_directory_path!
    log_job(script, cmd_envs, cwd)

    subprocess = Subprocess.new(cmd_envs, script.path, *ticket.arguments, chdir: cwd)
    subprocess.run do |stdout, stderr|
      if stdout
        self.stdout << stdout
        @write_pipe << stdout unless @write_pipe.closed?
      end
      if stderr
        self.stderr << stderr
        @write_pipe << stderr unless @write_pipe.closed?
      end
    end

    self.status = subprocess.exitstatus
    log_result
  ensure
    @write_pipe.close
    DEFAULT_LOGGER.info "Finished Job: #{self.id}"
  end

  def script
    @script ||= if node
      ticket.command.lookup_script(*node.ranks)
    else
      ticket.command.lookup_script
    end
  end

  def cmd_envs
    if node
      node.params.stringify_keys.dup.tap { |e| e['name'] = node.name }
    else
      {}
    end.tap do |env|
      env['SCRIPT_ROOT']      = Figaro.env.command_directory_path
      env['command']          = ticket.command.name
      env['request_username'] = ticket.request_username.to_s
      env['request_uid']      = ticket.request_uid.to_s
    end
  end

  def completed?
    !self.status.nil?
  end

  private

  def log_job(script, envs, cwd)
    DEFAULT_LOGGER.info <<~INFO

      # Job Definition ===============================================================
      # Ticket: #{ticket.id}
      # ID:     #{id}
      # Node:   #{node ? node.name : 'Not Applicable - No Context'}
      # Rank:   #{script.rank}
      # Script: #{script.path}
      # Args:   #{ticket.arguments}
      # Working Directory: #{cwd}
      # Environment Variables:
      #{envs.map { |k, v| "#{k}=#{v}" }.join("\n")}
    INFO
  end

  def log_result
    DEFAULT_LOGGER.info <<~INFO

      # Job Results ==================================================================
      # Ticket: #{ticket.id}
      # ID:     #{id}
      # Status: #{status}
      # STDOUT:
      #{stdout}

      # STDERR:
      #{stderr}
      # End Job Results ==============================================================
    INFO
  end
end

# See: http://stackoverflow.com/a/1162850/83386
class Subprocess
  attr_reader :exitstatus

  def initialize(env, *cmd, options)
    @env = env
    @cmd = cmd
    @options = options
    @exitstatus = nil
    @threads = []
  end

  def run(&block)
    Open3.popen3(@env, *@cmd, @options) do |stdin, stdout, stderr, thread|
      stdin.close
      { :out => stdout, :err => stderr }.each do |key, stream|
        @threads << Thread.new do
          until (line = stream.gets).nil? do
            if key == :out
              yield line, nil, thread if block_given?
            else
              yield nil, line, thread if block_given?
            end
          end
        end
      end

      @exitstatus = thread.value
      @threads.each(&:join)
    end
  end
end
