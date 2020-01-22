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
      Script.new(body: 'exit 1', variables: [])
    end

    let(:command) do
      Command.new(
        name: 'name1-something',
        summary: 'dummy',
        scripts: { 'default' => script }
      )
    end

    it 'is valid' do
      expect(command).to be_valid
    end

    describe '#name' do
      it 'can not be blank' do
        command.name = ''
        expect(command).not_to be_valid
      end

      it 'can not contain _' do
        command.name = 'bad_name'
        expect(command).not_to be_valid
      end
    end

    describe 'summary' do
      it 'can not be blank' do
        command.summary = ''
        expect(command).not_to be_valid
      end
    end

    describe 'description' do
      it 'can not be blank' do
        command.description = ''
        expect(command).not_to be_valid
      end
    end

    describe 'scripts' do
      it 'must be a hash' do
        command.scripts = [script]
        expect(command).not_to be_valid
      end

      it 'must have the default script' do
        command.scripts = {}
        expect(command).not_to be_valid
      end

      it 'must contain Script objects' do
        command.scripts.merge!({ 'string' => 'string' })
        expect(command).not_to be_valid
      end

      it 'must have valid scripts' do
        allow(script).to receive(:valid?).and_return(false)
        allow(script).to receive(:invalid?).and_return(true)
        expect(command).not_to be_valid
      end
    end
  end
end

