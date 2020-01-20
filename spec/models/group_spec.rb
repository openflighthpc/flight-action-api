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

RSpec.describe Group do
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
  end
end

