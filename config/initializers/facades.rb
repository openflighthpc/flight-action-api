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
yaml_str = File.read Figaro.env.nodes_config_path!
NodeFacade.facade_instance = NodeFacade::Standalone.new(YAML.load(yaml_str) || {})

pathname = Pathname.new(Figaro.env.command_directory_path)
commands = pathname.children.map do |c|
  next unless c.directory?
  next unless c.join("metadata.yaml").exist?

  md = YAML.load_file(c.join("metadata.yaml"))
  script_files = c.children.select { |s| s.file? && s.executable? }
  scripts = script_files.map do |sf|
    [ sf.basename(sf.extname).to_s, { script: sf.read, path: sf.to_s} ]
  end

  [ c.basename.to_s, md.merge(Hash[scripts]) ]
end
commands = Hash[commands.compact]
CommandFacade.facade_instance = CommandFacade::Standalone.new(commands)

CommandFacade.index_all.each do |command|
  next if command.valid?
  msg = <<~ERROR
    An error has occurred whilst loading the commands from:
  #{Figaro.env.command_directory_path!}

    CAUSE:
  #{command.errors.full_messages}

    COMMAND DETAILS:
    name:         #{command.name.to_s}
    summary:      #{command.summary.to_s}
    description:  #{command.description.to_s}
  ERROR

  if command.scripts.is_a?(Hash)
    command.scripts.values.select { |s| s.is_a?(Script) }.each do |script|
      msg += <<~SCRIPT

        # SCRIPT:
        rank:       #{script.rank.to_s}
        path:       #{script.path.to_s}
      SCRIPT
    end
  end

  raise msg
end
