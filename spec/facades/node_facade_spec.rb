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

RSpec.describe NodeFacade::Standalone do
  it 'strips the __meta__ key from its list' do
    facade = described_class.new(__meta__: 'data')
    expect(facade[:__meta__]).to be_nil
  end
end

RSpec.describe NodeFacade do
  context 'when in an isolated standalone mode' do
    around do |e|
      with_facade_dummies do
        described_class.facade_instance = \
          described_class::Standalone.new(nodes_data)
        e.call
      end
    end

    let(:nodes_data) { raise NotImplementedError }

    def generate_test_data
      {
        node1: {
          key: 'node1'
        },
        node2: {
          key: 'node2',
          ranks: ['duplicate', 'duplicate']
        },
        'node3' => {
          'ranks' => ['different', 'default'],
          'key' => 'node3'
        }
      }
    end

    describe '::find_by_name' do
      context 'with an empty set of nodes' do
        let(:nodes_data) { {} }

        it 'returns nil' do
          expect(described_class.find_by_name('missing')).to be_nil
        end
      end

      [:node1, :node2, 'node3'].each do |key|
        context "with the #{key} test set" do
          let(:nodes_data) { generate_test_data }
          let(:name) { key.to_s }
          let(:ranks) do
            raw_ranks = nodes_data[key][:ranks]&.dup || nodes_data[key]['ranks']&.dup || []
            raw_ranks << 'default'
            raw_ranks.uniq
          end
          subject { described_class.find_by_name(name) }

          it 'returns a a Node' do
            expect(subject).to be_a(Node)
          end

          it 'correctly names the node' do
            expect(subject.name).to eq(name)
          end

          it 'correctly sets the rank' do
            expect(subject.ranks).to eq(ranks)
          end

          it 'strips the ranks from the parameters' do
            expect(subject.params.keys).not_to include(:ranks)
          end

          it 'sets the parameters' do
            expect(subject.params[:key]).to eq(name.to_s)
          end
        end
      end
    end

    describe '::index_all' do
      let(:nodes_data) { generate_test_data }
      subject { described_class.index_all }

      it 'returns an array of Node objects' do
        expect(subject).to be_a(Array)
        subject.each { |n| expect(n).to be_a(Node) }
      end

      it 'returns the correctly named nodes' do
        expect(subject.map(&:name)).to contain_exactly(*nodes_data.keys.map(&:to_s))
      end
    end
  end
end

