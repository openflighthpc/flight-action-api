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

RSpec.describe GroupFacade do
  context 'when in standalone mode' do
    # Currently standalone is the only supported mode
    # around { 'noop' }

    describe '::find_by_name' do
      context 'with an explodable group' do
        let(:node_names) { ['node1', 'node2'] }
        let(:name) { node_names.join(',') }
        subject { described_class.find_by_name(name) }

        it 'returns a Group object' do
          expect(subject).to be_a(Group)
        end

        describe 'Group#nodes' do
          it 'returns the nodes as an Array' do
            expect(subject.nodes).to be_a(Array)
          end

          it 'returns each node object as a Node' do
            subject.nodes.each do |node|
              expect(node).to be_a(Node)
            end
          end

          it 'returns the correct node names' do
            expect(subject.nodes.map(&:name)).to contain_exactly(*node_names)
          end
        end
      end
    end
  end
end

