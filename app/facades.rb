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

module HasFacade
  extend ActiveSupport::Concern

  included do
    module self::Base
    end

    class self::Standalone
      include self.parent::Base
    end
  end

  class_methods do
    delegate_missing_to :facade_instance

    def facade_instance
      raise NotImplementedError
    end
  end
end

module GroupFacade
  include HasFacade

  def self.facade_instance
    @facade_instance = Standalone.new
  end

  module Base
    # Query for a Group object by its name alone
    # @param name [String] the name of the group
    # @return [Group] the group object containing the nodes
    # @return [nil] if it could not resolve the name
    def find_by_name(name)
      raise NotImplementedError
    end
  end

  class Standalone
    def find_by_name(name)
      node_names = Group.explode_names(name)
      return nil if node_names.nil?
      nodes = node_names.map { |n| NodeFacade.find_by_name(n) }
      Group.new(name: name, nodes: nodes)
    end
  end
end

module NodeFacade
  include HasFacade

  def self.facade_instance
    @facade_instance = Standalone.new
  end

  module Base
    # Query for a Node object by its name alone
    # @param name [String] the name of the node
    # @return [Node] the node object
    # @return [nil] if it could not resolve the name
    def find_by_name(name)
      raise NotImplementedError
    end
  end
end

