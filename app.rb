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

require 'sinja'
require 'sinja/method_override'
require 'hashie'

use Sinja::MethodOverride
register Sinja

BEARER_REGEX = /\ABearer\s(.*)\Z/

configure_jsonapi do |c|
  # c.conflict_exceptions << TemplateConflictError
  # c.validation_exceptions << ActiveModel::ValidationError

  # c.validation_formatter = ->(e) do
  #   e.model.errors.messages
    # relations = e.model.relations.keys.map(&:to_sym)
    # e.model.errors.messages.map do |src, msg|
    #   relations.include?(src) ? [src, msg, 'relationships'] : [src, msg]
    # end
  # end

  # Resource roles
  # c.default_roles = {
  #   index: [:user, :admin],
  #   show: [:user, :admin],
  #   create: :admin,
  #   update: :admin,
  #   destroy: :admin
  # }

  # # To-one relationship roles
  # c.default_has_one_roles = {
  #   pluck: [:user, :admin],
  #   prune: :admin,
  #   graft: :admin
  # }

  # # To-many relationship roles
  # c.default_has_many_roles = {
  #   fetch: [:user, :admin],
  #   clear: :admin,
  #   replace: :admin,
  #   merge: :admin,
  #   subtract: :admin
  # }
end

helpers do
  def serialize_model(model, options = {})
    JSONAPI::Serializer.serialize(model, options)
  end

  # def jwt_token
  #   if match = BEARER_REGEX.match(env['HTTP_AUTHORIZATION'] || '')
  #     match.captures.first
  #   else
  #     ''
  #   end
  # end

  # def role
  #   token = Token.from_jwt(jwt_token)
  #   if token.admin && token.valid
  #     :admin
  #   elsif token.valid
  #     :user
  #   else
  #     :unknown
  #   end
  # end
end

freeze_jsonapi

