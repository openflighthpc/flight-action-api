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

require 'spec_helper'

RSpec.describe Command do
  context 'with a simple command setup' do
    let(:script) do
      Script.new(body: 'exit 1', variables: [], rank: 'default')
    end

    let(:command) do
      Command.new(
        name: 'name1-something',
        summary: 'dummy',
        scripts: { 'default' => script }
      )
    end

    subject { command }

    it 'is valid' do
      expect(subject).to be_valid
    end

    describe '#name' do
      it 'can not be blank' do
        subject.name = ''
        expect(subject).not_to be_valid
      end

      it 'can not contain _' do
        subject.name = 'bad_name'
        expect(subject).not_to be_valid
      end
    end

    describe '#summary' do
      it 'can not be blank' do
        subject.summary = ''
        expect(subject).not_to be_valid
      end
    end

    describe '#description' do
      it 'can not be blank' do
        subject.description = ''
        expect(subject).not_to be_valid
      end
    end

    describe '#scripts' do
      it 'must be a hash' do
        subject.scripts = [script]
        expect(subject).not_to be_valid
      end

      it 'must have the default script' do
        subject.scripts = {}
        expect(subject).not_to be_valid
      end

      it 'must contain Script objects' do
        subject.scripts.merge!({ 'string' => 'string' })
        expect(subject).not_to be_valid
      end

      it 'must have valid scripts' do
        allow(script).to receive(:valid?).and_return(false)
        allow(script).to receive(:invalid?).and_return(true)
        expect(subject).not_to be_valid
      end

      it 'must having matching ranks' do
        subject.scripts.merge!({ 'wrong' => script })
        expect(subject).not_to be_valid
      end
    end

    describe '#aliases' do
      it 'can be set directly' do
        name = 'direct'
        subject.aliases = name
        expect(subject).to be_valid
        expect(subject.aliases).to contain_exactly(name)
      end

      it 'can be set via an array' do
        names = ['alias1', 'alias2']
        subject.aliases = names
        expect(subject).to be_valid
        expect(subject.aliases).to contain_exactly(*names)
      end

      it 'must not contain empty string' do
        subject.aliases = ''
        expect(subject).not_to be_valid
      end

      it 'must not contain underscores' do
        subject.aliases = 'name_other'
        expect(subject).not_to be_valid
      end

      it 'may contain hypens' do
        subject.aliases = 'name-other'
        expect(subject).to be_valid
      end
    end
  end

  context 'with a command with multiple scripts' do
    let(:ranks) { ['first', 'second', 'third'] }
    let(:default) { Script.new(body: 'echo default', rank: 'default') }
    let(:scripts) do
      ranks.map { |r| [r, Script.new(body: "echo #{r}", rank: r)] }
           .to_h
           .tap { |h| h['default'] = default }
    end

    subject do
      described_class.new(
        name: 'test',
        summary: 'test',
        scripts: scripts
      )
    end

    it 'is valid' do
      expect(subject).to be_valid
    end

    describe '#lookup_script' do
      it 'can find the default script' do
        expect(subject.lookup_script('default')).to eq(default)
      end

      it 'returns the default if the rank is missing' do
        expect(subject.lookup_script('missing', 'missing2')).to eq(default)
      end

      it 'can find an alternative script' do
        rank = ranks.first
        expect(subject.lookup_script(rank)).to eq(scripts[rank])
      end

      it 'selects the first match' do
        rank = ranks.last
        lookup = ['missing', rank, ranks.first]
        expect(subject.lookup_script(*lookup)).to eq(scripts[rank])
      end
    end
  end
end
