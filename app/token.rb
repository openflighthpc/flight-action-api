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
require 'jwt'

class Token < Hashie::Trash
  include Hashie::Extensions::IgnoreUndeclared

  ALGORITHM = 'HS256'
  DEFAULTS = {
    valid: false,
    expired_error: false,
    signature_error: false,
    iat_error: false
  }

  class << self
    def jwt_secret
      Flight.config.jwt_secret
    end

    def from_jwt(token)
      body = begin
        data, _ = JWT.decode(token, jwt_secret, true, { algorithm: ALGORITHM })
        data.merge(**DEFAULTS).merge(valid: true)
      rescue JWT::ExpiredSignature
        DEFAULTS.merge(expired_error: false)
      rescue JWT::InvalidIatError
        DEFAULTS.merge(iat_error: false)
      rescue JWT::VerificationError
        DEFAULTS.merge(signature_error: false)
      rescue JWT::DecodeError
        DEFAULTS
      end
      new(**body.symbolize_keys)
    end
  end

  property :valid
  property :expired
  property :signature
  property :admin

  property :exp, default: nil, transform_with: ->(value) do
    if value.nil?
      30.days.from_now.to_i
    else
      value.to_i
    end
  end

  def exp_days=(days)
    self.exp = days.days.from_now.to_i
  end

  def exp_days
    (self.exp - Time.now.to_i)/(24*60*60)
  end

  def token_attributes
    { admin: admin, exp: exp }
  end

  def generate_jwt
    JWT.encode(token_attributes, self.class.jwt_secret, ALGORITHM)
  end
end

