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
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, default: ->() { SecureRandom.hex(20) }
  attribute :context
  attribute :command
  attribute :arguments, default: []
  attribute :jobs

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

  def build_jobs
    DEFAULT_LOGGER.info "Building Ticket: #{self.id}"
    self.class.registry.add(self)
    self.jobs = nodes.map do |n|
      Job.new(node: n, ticket: self).tap do |job|
        DEFAULT_LOGGER.info "Add Job \"#{job.node.name}\": #{job.id}"
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

  def stream
    mutex = Mutex.new
    tag_lines = context.is_a?(Group)

    threads = jobs.map do |job|
      Thread.new(job) do |job|
        until (line = job.read_pipe.gets).nil? do
          tagged_line = tag_lines ? "#{job.node.name}: #{line}" : line
          mutex.synchronize do
            yield tagged_line
          end
        end
      end
    end

    threads.each(&:join)
    jobs.each { |job| job.read_pipe.close unless job.read_pipe.closed? }
    self.class.registry.remove(self)
  end

  class << self
    delegate :find_by_id, :all, to: :registry

    def registry
      @registry ||= Registry.new
    end
  end

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
end
