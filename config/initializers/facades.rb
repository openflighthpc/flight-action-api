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

GroupFacade.facade_instance = if Figaro.env.full_upstream
                                raise 'Full Upstream Mode is not currently supported'
                              else
                                GroupFacade::Exploding.new
                              end

NodeFacade.facade_instance =  if Figaro.env.remote_url
                                raise 'Partial Upstream Mode is not currently supported'
                              else
                                yaml_str = File.read Figaro.env.nodes_config_path!
                                NodeFacade::Standalone.new(YAML.load(yaml_str) || {})
                              end

cmd_yaml = YAML.load(File.read(Figaro.env.commands_config_path!)) || {}
CommandFacade.facade_instance = CommandFacade::Standalone.new(cmd_yaml)

# Ensure all the facades are valid
CommandFacade.index_all.each do |command|
  next if command.valid?
  msg = <<~ERROR
    An error has occurred whilst loading the commands config:
    #{Figaro.env.commands_config_path!}

    CAUSE:
    #{command.errors.full_messages}

    COMMAND DETAILS:
    name:         #{command.name.to_s}
    summary:      #{command.summary.to_s}
    description:  #{command.description.to_s}
    aliases:      #{command.aliases.to_s}
  ERROR

  if command.scripts.is_a?(Hash)
    command.scripts.values.select { |s| s.is_a?(Script) }.each do |script|
      msg += <<~SCRIPT

        # SCRIPT: #{script.rank.to_s}
        rank:       #{script.rank.to_s}
        variables:  #{script.variables.to_s}
        body:       #{script.body.to_s}
      SCRIPT
    end
  end

  raise msg
end

# Ensure the aliases and names are all unique
dups = CommandFacade.index_all.map { |c| [c.name, c.aliases] }.flatten
                    .each_with_object(Hash.new(0)) { |n, h| h[n] += 1 }
                    .select { |_, v| v > 1 }

unless dups.empty?
  raise <<~ERROR.squish
    Can not continue as duplicate names/ aliases have been dectected.
    Please remove the following duplications:
    #{dups.keys.join(', ')}
  ERROR
end

