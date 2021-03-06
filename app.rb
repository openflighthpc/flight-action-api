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

require 'sinja'
require 'sinja/method_override'
require 'hashie'

module AuthHelpers
  BEARER_REGEX = /\ABearer\s(.*)\Z/

  def jwt_token
    if match = BEARER_REGEX.match(env['HTTP_AUTHORIZATION'] || '')
      match.captures.first
    else
      ''
    end
  end

  def role
    token = Token.from_jwt(jwt_token)
    if token.valid
      :user
    else
      :unknown
    end
  end
end

class App < Sinatra::Base
  before do
    env['HTTP_ACCEPT'] = 'application/vnd.api+json'
  end

  use Sinja::MethodOverride
  register Sinja

  configure_jsonapi do |c|
    c.not_found_exceptions << NotFoundError
    c.validation_exceptions << ActiveModel::ValidationError

    c.validation_formatter = ->(e) do
      e.model.errors.messages.transform_values { |v| v.join(', ') }
    end

    # Resource roles
    c.default_roles = {
      index: :user,
      show: :user,
      create: :user,
      update: :user,
      destroy: :user
    }

    # To-one relationship roles
    c.default_has_one_roles = {
      pluck: :user,
      prune: :user,
      graft: :user
    }

    # To-many relationship roles
    c.default_has_many_roles = {
      fetch: :user,
      clear: :user,
      replace: :user,
      merge: :user,
      subtract: :user
    }
  end

  before do
    NodeFacade.reload
    Command.reload
  end

  helpers do
    include AuthHelpers

    # Explicitly define the `role` method in the `helpers` block so that Sinja
    # figures out that it has been defined.  Calling `super` delegates to the
    # definition in AuthHelpers.
    def role
      super
    end
  end

  resource :groups, pkre: /[-(?:%5B)(?:%5D),\w]+/ do
    helpers do
      def find(id)
        GroupFacade.find_by_name(id)
      end
    end

    index { [] }

    show

    has_many :nodes do
      fetch { resource.nodes }
    end
  end

  resource :nodes, pkre: /[-\w]+/ do
    helpers do
      def find(id)
        NodeFacade.find_by_name(id)
      end
    end

    index { NodeFacade.index_all }

    show
  end

  resource :commands, pkre: /[-[[:alnum:]]]+/ do
    helpers do
      def find(id)
        Command.find_by_name(id)
      end
    end

    index { Command.all }

    show
  end

  resource :tickets, pkre: /\w+/ do
    helpers do
      # Explicitly prevent the Ticket from being loaded
      def find(id)
        Ticket.find_by_id(id)
      end

      def validate!
        resource.validate!
        resource.build_jobs
        Thread.new { resource.run }
      end

      def not_found_relation(rio)
        raise NotFoundError.new(rio[:type], rio[:id])
      end
    end

    index { Ticket.all }
    show

    create do |attributes|
      attrs = [:arguments, :request_uid, :request_username].map do |key|
        [key, attributes[key]]
      end.to_h
      ticket = Ticket.new(**attrs)
      next [ticket.id, ticket]
    end

    has_one :command do
      graft(sideload_on: :create) do |rio|
        resource.command = Command.find_by_name(rio[:id]) or not_found_relation(rio)
      end
    end

    has_one :context do
      graft(sideload_on: :create) do |rio|
        resource.context = case rio[:type]
                           when 'nodes'
                             NodeFacade.find_by_name(rio[:id]) or not_found_relation(rio)
                           when 'groups'
                             GroupFacade.find_by_name(rio[:id]).tap do |group|
                               if group.nil?
                                 not_found_relation(rio)
                               end
                               if GroupFacade.facade_instance.is_a?(GroupFacade::Exploding) && group.nodes.empty?
                                 not_found_relation(rio)
                               end
                             end
                           end
      end
    end
  end

  freeze_jsonapi
end

require 'sinatra/streaming'

class Stream < Sinatra::Base
  helpers Sinatra::Streaming
  helpers AuthHelpers

  # Directs nginx not to buffer the streaming response
  # NOTE: nginx will always compress text/html if gzip is on
  before do
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Last-Modified'] = Time.current.httpdate
    response.headers['Content-Type'] = 'text/plain'
  end

  get('/tickets/:id') do
    halt 403 unless role == :user
    ticket = Ticket.find_by_id(params[:id])
    halt 404 if ticket.nil?
    stream do |out|
      ticket.stream do |line|
        out << line unless out.closed?
      end
      ticket.remove if ticket.completed?
    end
  end
end
