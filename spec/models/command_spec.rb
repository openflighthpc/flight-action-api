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

require 'spec_helper'

RSpec.describe Command do
  let(:script) do
    Script.new(path: '/dev/null', rank: 'default')
  end

  context 'with a simple command setup' do
    let(:command) do
      Command.new(
        name: 'command-spec-command',
        summary: 'dummy',
        scripts: [script]
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

    describe 'summary' do
      it 'can not be blank' do
        subject.summary = ''
        expect(subject).not_to be_valid
      end
    end

    describe 'description' do
      it 'can not be blank' do
        subject.description = ''
        expect(subject).not_to be_valid
      end
    end

    describe 'scripts' do
      it 'must be an array' do
        subject.scripts = { broken: script }
        expect(subject).not_to be_valid
      end

      it 'must have the default script' do
        subject.scripts = {}
        expect(subject).not_to be_valid
      end

      it 'must contain Script objects' do
        subject.scripts << 'string'
        expect(subject).not_to be_valid
      end

      it 'must have valid scripts' do
        allow(script).to receive(:valid?).and_return(false)
        allow(script).to receive(:invalid?).and_return(true)
        expect(subject).not_to be_valid
      end
    end
  end

  context 'with a command with multiple scripts' do
    let(:ranks) { ['first', 'second', 'third'] }
    let(:default) { Script.new(path: '/dev/null', rank: 'default') }
    let(:scripts) do
      ranks.map { |r| Script.new(path: '/dev/null', rank: r) } << default
    end
    let(:has_context) { true }

    subject do
      described_class.new(
        name: 'test',
        summary: 'test',
        scripts: scripts,
        has_context: has_context
      )
    end

    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'when has_context is false' do
      let(:has_context) { false }
      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    describe '#lookup_script' do
      it 'can find the default script' do
        expect(subject.lookup_script('default')).to eq(default)
      end

      it 'returns the default if the rank is missing' do
        expect(subject.lookup_script('missing', 'missing2')).to eq(default)
      end

      it 'can find the specified script' do
        rank = ranks.first
        script = scripts.find { |s| s.rank == rank }
        expect(subject.lookup_script(rank)).to eq(script)
      end

      it 'selects the first match' do
        rank = ranks.last
        script = scripts.find { |s| s.rank == rank }
        lookup = ['missing', rank, ranks.first]
        expect(subject.lookup_script(*lookup)).to eq(script)
      end
    end
  end

  describe '#syntax' do
    let(:syntax) { raise NotImplementedError }
    let(:has_context) { raise NotImplementedError }

    subject do
      opts = {
        name: 'Syntax Demo',
        summary: 'demo',
        description: 'demo',
        scripts: [script],
        has_context: has_context
      }.tap { |o| o[:syntax] = syntax unless syntax.nil? }
      described_class.new(**opts)
    end

    context 'with the default syntax' do
      let(:syntax) { nil }

      context 'with has_context' do
        let(:has_context) { true }
        it { should be_valid }

        it 'should be NAME' do
          expect(subject.syntax).to eq('NAME')
        end
      end

      context 'without has_context' do
        let(:has_context) { false }
        it { should be_valid }

        it 'should be empty string' do
          expect(subject.syntax).to eq('')
        end
      end
    end

    context 'with a syntax prefixed with NAME' do
      let(:syntax) { 'NAME OTHER STUFF' }

      context 'with has_context' do
        let(:has_context) { true }
        it { should be_valid }

        it 'returns unmodified' do
          expect(subject.syntax).to eq(syntax)
        end
      end

      context 'without has_context' do
        let(:has_context) { false }
        it { should be_valid }

        it 'returns unmodified' do
          expect(subject.syntax).to eq(syntax)
        end
      end
    end

    context 'with a syntax without the NAME prefix' do
      let(:syntax) { 'OTHER STUFF' }

      context 'with has_context' do
        let(:has_context) { true }
        it { should_not be_valid }
      end

      context 'without has_context' do
        let(:has_context) { false }
        it { should be_valid }

        it 'returns unmodified' do
          expect(subject.syntax).to eq(syntax)
        end
      end
    end
  end
end
