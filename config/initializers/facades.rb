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

GroupFacade.facade_instance = GroupFacade::Exploding.new

def NodeFacade.load!
  Flight.logger.info("Loading nodes from #{Flight.config.nodes_config_path}")
  @node_mtime = File.mtime(Flight.config.nodes_config_path)
  nodes = YAML.load_file(Flight.config.nodes_config_path) || {}
  NodeFacade.facade_instance = NodeFacade::Standalone.new(nodes)
end
def NodeFacade.load
  self.load!
rescue Psych::SyntaxError
  Flight.logger.warn("Unable to load nodes: #{$!.message}")
end
def NodeFacade.reload
  node_mtime = File.mtime(Flight.config.nodes_config_path)
  self.load if @node_mtime < node_mtime
end


NodeFacade.load!
Command.load!
