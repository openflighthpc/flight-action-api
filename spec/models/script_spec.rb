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

RSpec.describe Script do
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

    subject { script }

    it 'is valid' do
      expect(command).to be_valid
    end

    describe '#variables' do
      it 'can wrap bare strings' do
        str = 'string'
        subject.variables = str
        expect(subject.variables).to contain_exactly(str)
      end

      it 'must not contain empty string' do
        subject.variables = ['']
        expect(subject).not_to be_valid
      end

      it 'can be unset' do
        subject.variables = nil
        expect(subject.variables).to eq([])
      end

      it 'may contain various other strings' do
        subject.variables = ['a', 'A', '1', 'a-b_c']
        expect(subject).to be_valid
      end
    end
  end
end


