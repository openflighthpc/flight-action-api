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

RSpec.describe GroupFacade::Exploding do
  describe '::explode_names' do
    [
      'n[', 'n]', 'n[]', 'n[1]', 'n[-]', 'n[1-]', 'n[-1]', 'n[a-1]', 'n[1-a]', 'n0,n[', '[1-2]'
    ].each do |name|
      it "returns nil for illegal name: #{name}" do
        expect(described_class.explode_names(name)).to eq(nil)
      end
    end

    it 'can explode names delimited by commas' do
      nodes = ['n', 'node1', 'node2', 'node3']
      expect(described_class.explode_names(nodes.join(','))).to contain_exactly(*nodes)
    end

    it 'ignores excess delimitors' do
      expect(described_class.explode_names(',,,n,,')).to eq(['n'])
    end

    it 'can expand ranges' do
      nodes = (1..10).map { |i| "node#{i}" }
      expect(described_class.explode_names('node[1-10]')).to contain_exactly(*nodes)
    end

    it 'can pad zeros in the range expansion' do
      s_nodes = (1..9).map { |i| "node00#{i}" }
      d_nodes = (10..99).map { |i| "node0#{i}" }
      t_nodes = (100..110).map { |i| "node#{i}" }
      nodes = [*s_nodes, *d_nodes, *t_nodes]
      expect(described_class.explode_names('node00[001-110]')).to contain_exactly(*nodes)
    end
  end
end

RSpec.describe GroupFacade do
  context 'when in exploding mode' do
    around(:all) do |example|
      with_facade_dummies do
        GroupFacade.facade_instance = described_class::Exploding.new
        example.call
      end
    end

    describe '::find_by_name' do
      context 'with a stubbed NodeFacade that returns Node objects' do
        before do
          allow(NodeFacade).to receive(:find_by_name).and_wrap_original do |_, name|
            Node.new(name: name, params: {})
          end
        end

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

      context 'with a stubbed NodeFacade that returns nil' do
        before do
          allow(NodeFacade).to receive(:find_by_name).and_return(nil)
        end

        let(:node_names) { ['node1', 'node2'] }
        let(:name) { node_names.join(',') }
        subject { described_class.find_by_name(name) }

        it 'returns an empty array of nodes' do
          expect(subject.nodes).to be_a(Array)
          expect(subject.nodes).to be_empty
        end
      end

      context 'when the name can not be exploded' do
        before do
          allow(GroupFacade::Exploding).to receive(:explode_names).and_return(nil)
        end

        it 'returns nil' do
          expect(described_class.find_by_name('stubbed')).to eq(nil)
        end
      end
    end

    describe '::index_all' do
      it 'returns an empty array' do
        expect(described_class.index_all).to eq([])
      end
    end
  end
end

