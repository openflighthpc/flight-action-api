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

RSpec.describe '/tickets' do
  describe 'POST' do
    let(:payload) { raise NotImplementedError }

    before do
      user_headers
      post '/tickets', payload.to_json
    end

    context 'with a has-context command and with a request context' do
      let(:payload) do
        build_payload(Ticket.new, include_id: false, relationships: {
          command: Command.find_by_name('ping'),
          context: NodeFacade.find_by_name('node1')
        })
      end

      it 'returns 201' do
        expect(last_response).to be_created
      end
    end

    context 'with a has-context command and without a request context' do
      let(:payload) do
        build_payload(Ticket.new, include_id: false, relationships: {
          command: Command.find_by_name('ping')
        })
      end

      it 'returns 422' do
        expect(last_response).to be_unprocessable
      end
    end

    context 'with a non-has-context command and without a request context' do
      let(:payload) do
        build_payload(Ticket.new, include_id: false, relationships: {
          command: Command.find_by_name('nmap')
        })
      end

      it 'returns 201' do
        expect(last_response).to be_created
      end
    end

    context 'without a non-has=context command and with a request context' do
      let(:payload) do
        build_payload(Ticket.new, include_id: false, relationships: {
          command: Command.find_by_name('nmap'),
          context: NodeFacade.find_by_name('node1')
        })
      end

      it 'returns 422' do
        expect(last_response).to be_unprocessable
      end
    end
  end
end
