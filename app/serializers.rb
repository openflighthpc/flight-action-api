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

class CommandSerializer
  include JSONAPI::Serializer

  def id
    object.name
  end

  attributes :name, :description, :summary, :confirmation, :has_context
  attribute :syntax do
    if object.syntax
      object.syntax
    elsif object.has_context
      'NAME'
    else
      ''
    end
  end
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

  has_one :command
  has_one :context
  has_many :jobs

  def links
    super.tap do |h|
      h[:output_stream] = "#{base_url}/streaming/#{type}/#{id}"
    end
  end
end

class JobSerializer
  include JSONAPI::Serializer

  has_one :node
  has_one :ticket

  attributes :stdout, :stderr, :status
end
