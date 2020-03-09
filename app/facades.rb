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

module CommandFacade
  include HasFacade

  module Base
    # Query for a Command object by its name alone
    # @param name [String] the name of the command
    # @return [Command] the command object
    # @return [nil] if the command is missing
    def find_by_name(name)
      raise NotImplementedError
    end

    # Query for all the available commands
    # @return [Array<Node>] the list of commands
    def index_all
    end
  end

  define_facade('Dummy')

  define_facade('Standalone', Hash) do
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess

    def initialize(input)
      cmd_hash = input.to_h.stringify_keys.tap { |h| h.delete('__meta__') }
                  .map do |raw_name, data|
        name = raw_name.to_s.gsub('_', '-')
        help = data['help'].symbolize_keys
        scripts = data.reject { |k, _| k == 'help' }
                      .map do |rank, attr|
          attr = attr.to_h.symbolize_keys
          script = Script.new rank: rank, body: attr[:script], variables: attr[:variables]
          [rank, script]
        end.to_h
        cmd = Command.new(name: name, scripts: scripts, **help)
        [name, cmd]
      end
      super(cmd_hash)
    end

    def index_all
      map
    end

    def find_by_name(name)
      [name.to_s]
    end

    def each
      super { |_, cmd| yield cmd }
    end
  end
end

