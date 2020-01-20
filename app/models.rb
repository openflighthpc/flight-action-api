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

class Command < BaseHashieDashModel
end

class Node < BaseHashieDashModel
  property :name, required: true
  property :params, required: true
end

class Group < BaseHashieDashModel
  EXPLODE_REGEX = /\A(?<leader>[[:alnum:]]+)(\[(?<low>\d+)\-(?<high>\d+)\])?\Z/
  PADDING_REGEX = /0*\Z/

  def self.explode_names(input)
    parts = input.split(',').reject(&:empty?)
    return nil unless parts.all? { |p| EXPLODE_REGEX.match?(p) }
    parts.map do |part|
      captures = EXPLODE_REGEX.match(part).named_captures.reject { |_, v| v.nil? }
      if captures.key?('low')
        leader = captures['leader']
        max_pads = PADDING_REGEX.match(leader).to_s.length
        stripped_leader = leader.sub(PADDING_REGEX, '')
        low = captures['low'].to_i
        high = captures['high'].to_i
        (low..high).map do |index|
          pads = max_pads - index.to_s.length + 1
          "#{stripped_leader}#{'0' * pads if pads > 0}#{index}"
        end
      else
        part
      end
    end.flatten
  end

  DataHash.class_exec do
    property  :name, required: true
    property  :nodes, default: []
  end
end

class Ticket < BaseHashieDashModel
end

class Job < BaseHashieDashModel
end

