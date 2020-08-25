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

require 'active_model'

class Ticket
  class Registry
    def initialize
      @mutex = Mutex.new
      @tickets = {}
    end

    def all
      @tickets.values
    end

    def find_by_id(id)
      @tickets[id]
    end

    def add(ticket)
      @mutex.synchronize do
        @tickets[ticket.id] = ticket
      end
    end

    def remove(ticket)
      @mutex.synchronize do
        @tickets.delete(ticket.id)
      end
    end
  end

  class << self
    delegate :find_by_id, :all, to: :registry

    def registry
      @registry ||= Registry.new
    end
  end

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, default: ->() { SecureRandom.hex(20) }
  attribute :context
  attribute :command
  attribute :arguments, default: []
  attribute :jobs, default: ->() { Array.new } # Ensure a new array is created each time

  validates :context,  presence: true, if: :command_has_context?
  validates :context,  absence: true, unless: :command_has_context?
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

  def build_jobs
    DEFAULT_LOGGER.info "Building Ticket: #{self.id}"
    self.class.registry.add(self)
    @collated_stream = CollatedStream.new(tag_lines: context.is_a?(Group))

    # Adds Node Base Jobs
    nodes.map do |n|
      self.jobs << Job.new(node: n, ticket: self).tap do |job|
        DEFAULT_LOGGER.info "Add Job \"#{job.node.name}\": #{job.id}"
        @collated_stream.add(job)
      end
    end

    # Adds the no-context job if required
    unless command_has_context?
      self.jobs << Job.new(node: nil, ticket: self).tap do |job|
        DEFAULT_LOGGER.info "Add Job (No Contexting): #{job.id}"
        @collated_stream.add(job)
      end
    end
  end

  def run
    DEFAULT_LOGGER.info "Starting Ticket: #{self.id}"
    job_threads =
      begin
        Integer(Figaro.env.job_threads)
      rescue ArgumentError, TypeError
        1
      end
    Parallel.each(self.jobs, in_threads: job_threads) do |job|
      job.run
    end
  ensure
    DEFAULT_LOGGER.info "Finished Ticket: #{self.id}"
  end

  def completed?
    jobs.all?(&:completed?)
  end

  def remove
    self.class.registry.remove(self)
  end

  def stream
    @collated_stream.listen do |line|
      yield line
    end
  end

  def command_has_context?
    command.has_context
  end
end

# Collates and records output from jobs as it is produced.
class CollatedStream
  def initialize(tag_lines:)
    @lines = []
    @listeners = []
    @mutex = Mutex.new
    @tag_lines = tag_lines
    @threads = []
  end

  def add(job)
    @threads << Thread.new(job) do
      until (line = job.read_pipe.gets).nil? do
        tagged_line = @tag_lines ? "#{job.node.name}: #{line}" : line
        @mutex.synchronize do
          @lines << tagged_line
          @listeners.each do |listener|
            begin
              listener.call(tagged_line)
            rescue
            end
          end
        end
      end
    end
  end

  # Yields:
  #
  #  - all output already read from the jobs
  #  - new output from the jobs as it is read.
  def listen(&block)
    @mutex.synchronize do
      @lines.each do |line|
        yield line
      end
      @listeners << block
    end
    @threads.each(&:join)
  end
end
