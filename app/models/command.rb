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

require 'hashie'
require 'active_model'

class Command < Hashie::Dash
  include Hashie::Extensions::IgnoreUndeclared
  include Hashie::Extensions::Dash::PropertyTranslation
  include ActiveModel::Validations

  property :name
  property :summary
  property :description,  from: :summary
  property :confirmation, default: nil
  property :scripts,      default: []
  property :has_context,  default: true

  # Flags the output to be displayed sequentially, the jobs will still run
  # concurrently
  property :sequential_output, default: false

  # TODO: Reconsider how the default is set. Currently it can't tell the
  # difference between 'has_context: all_nodes' and an explicitly defined
  # string. For the time being `has_context: all_nodes' flag needs to be
  # combined with 'syntax: ""'
  property :syntax,       from: :has_context, with: ->(s) do
    case s
    when String
      s
    when TrueClass
      'NAME'
    else
      ''
    end
  end

  validates :name,        presence: true, format: {
    with: /\A[^_]*\Z/,    message: 'must not contain underscores'
  }
  validates :summary,     presence: true
  validates :description, presence: true

  validates :has_context, inclusion: { in: [true, false, nil, 'all_nodes'] }
  validates :sequential_output, inclusion: { in: [true, false, nil] }

  validate :validate_has_a_default_script
  validate :validate_scripts_are_valid
  validate :validate_no_context_only_has_a_default_script
  validate :validate_syntax_name_prefix, if: :has_explicit_context?

  class << self
    delegate :load, :load!, :reload, :find_by_name, :all,
      to: :registry

    def registry
      @registry ||= Registry.new
    end
  end

  def lookup_script(*ranks)
    script_ranks = scripts.map(&:rank)
    selected_rank = (ranks & script_ranks).first || 'default'
    scripts.detect { |script| script.rank ==  selected_rank }
  end

  def default_script
    scripts.detect { |script| script.rank == 'default' if script.is_a? Script }
  end

  ##
  # Checks if the context needs to be explicitly set
  def has_explicit_context?
    has_context == true
  end

  ##
  # Checks if the context is not explcitly/implicitly set
  def has_no_context?
    !has_context
  end

  private

  def validate_scripts_are_valid
    if scripts.is_a? Array
      scripts.select do |script|
        case script
        when Script
          unless script.valid?
            errors.add(:"script:#{script.rank}", script.errors.full_messages.join(','))
          end
        else
          errors.add(:scripts, 'must only contain Script objects')
        end
      end
    else
      errors.add(:scripts, 'must be an array')
    end
  end

  def validate_has_a_default_script
    if default_script.nil?
      errors.add(:scripts, 'does not contain the default script')
    end
  end

  def validate_no_context_only_has_a_default_script
    if scripts.is_a?(Array) && scripts.length > 1 && has_no_context?
      errors.add(:scripts, 'must only contain the default script as has_context is false')
    end
  end

  def validate_syntax_name_prefix
    unless syntax.to_s.match?(/\ANAME(\s.*)?/)
      errors.add(:syntax, 'must be prefixed with NAME as has_context has been set')
    end
  end

  class Registry
    def load
      old_commands = @commands.dup
      old_mtime = @mtime.dup
      self.load!
    rescue
      DEFAULT_LOGGER.info("Unable to load nodes: #{$!.message}")
      @commands = old_commands
      @mtime = old_mtime
    end

    def load!
      pathname = Pathname.new(Figaro.env.command_directory_path)
      DEFAULT_LOGGER.info("Loading commands from #{pathname}")
      commands = pathname.children.map do |c|
        next unless c.directory?
        next unless c.join("metadata.yaml").exist?

        md = YAML.load_file(c.join("metadata.yaml"))
        script_files = c.children.select { |s| s.file? && s.executable? }
        scripts = script_files.map do |sf|
          rank = sf.basename(sf.extname).to_s
          Script.new(rank: rank, path: sf.to_s)
        end
        Command.new(
          name: c.basename.to_s,
          scripts: scripts,
          confirmation: md['confirmation'],
          **md['help'].symbolize_keys,
        )
      end
      assert_commands_valid(commands)
      @commands = commands
      @mtime = last_modified
    end

    def reload
      self.load if @mtime.nil? || @mtime < last_modified
    end

    def all
      @commands
    end

    def find_by_name(name)
      @commands.detect { |c| c.name == name }
    end

    private

    def assert_commands_valid(commands)
      commands.each do |command|
        next if command.valid?
        msg = <<~ERROR
          An error has occurred whilst loading the commands.

          CAUSE:
        #{command.errors.full_messages}

          COMMAND DETAILS:
          name:         #{command.name.to_s}
          syntax:       #{command.syntax.to_s}
          has-context:  #{command.has_context.to_s}
          summary:      #{command.summary.to_s}
          description:  #{command.description.to_s}
        ERROR

        unless command.scripts.nil?
          command.scripts.each do |script|
            msg += <<~SCRIPT

              # SCRIPT:
              rank:       #{script.rank.to_s}
              path:       #{script.path.to_s}
            SCRIPT
          end
        end

        raise msg
      end
    end

    def last_modified
      pathname = Pathname.new(Figaro.env.command_directory_path)
      pathname.children.map { |c| File.mtime(c) }.max
    end
  end
end
