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

class CommandSerializer
  include JSONAPI::Serializer

  def id
    object.name
  end

  attributes :name, :description, :summary, :aliases
end

class NodeSerializer
  include JSONAPI::Serializer

  def id
    object.name
  end

  attributes :name
end

class GroupSerializer
  include JSONAPI::Serializer

  has_many :nodes

  def id
    object.name
  end

  attributes :name
end

class TicketSerializer
  include JSONAPI::Serializer

  # Dummy attribute so the 'attributes' key is always set
  # Some clients (incorrectly) assume the 'attributes' key will always be set
  # https://github.com/qvantel/jsonapi-client/issues/25
  attribute(:true) { true }

  has_one :command
  has_one :context
  has_many :jobs
end

class JobSerializer
  include JSONAPI::Serializer

  has_one :node
  has_one :ticket

  attributes :stdout, :stderr, :status
end

