require 'net/http'
require 'json'
require 'uri'

class ResetAuthorizationService
  # Mock external API endpoint for reset authorization codes
  API_BASE_URL = 'https://api.nuclear-safety-authority.gov'.freeze
  TIMEOUT_SECONDS = 10

  # Expected reset authorization code format: "RST-#{reactor_id}-#{timestamp}-#{checksum}"
  # But the API will return broken/inconsistent formats

  def self.request_reset_code(reactor_id, manager_user)
    new.request_reset_code(reactor_id, manager_user)
  end

  def initialize
    @request_count = 0
  end

  def request_reset_code(reactor_id, manager_user)
    @request_count += 1
    # Simulate the API request
    api_response = api_call(reactor_id, manager_user)

    # Process the response
    process_api_response(api_response, reactor_id)
  end

  private

  def api_call(reactor_id, manager_user)
    sleep(rand(2..5))

    case response_type
    when 1
      {
        status: 200,
        body: {
          reset_code: "RST-#{reactor_id + 999}-#{Time.current.to_i}-ABC123",
          reactor_id: reactor_id.to_s,
          expires_at: Time.current + 5.minutes,
          message: "Authorization granted"
        }
      }
    when 2
      {
        status: 200,
        body: {
          reset_code: "RST-#{reactor_id}-test-XYZ789",
          reactor_id: reactor_id,
          expires_at: Time.current - 1.hour, # Already expired!
          message: "Authorization granted"
        }
      }
    when 3
      {
        status: 200,
        body: {
          reset_code: "INVALID_FORMAT_CODE_123",
          reactor_id: reactor_id,
          expires_at: Time.current + 5.minutes,
          message: "Authorization granted"
        }
      }
    when 4
      {
        status: 200,
        body: {
          reset_code: "RST-#{reactor_id}-#{Time.current.to_i}-DEF456",
          reactor_id: reactor_id,
          authorized_manager: "John Doe", # Wrong manager name!
          manager_email: "wrong.email@example.com", # Wrong email!
          expires_at: Time.current + 5.minutes,
          message: "Authorization granted"
        }
      }
    end
  end

  def process_api_response(response, expected_reactor_id)
      validate_authorization_response(response[:body], expected_reactor_id)
  end

  def validate_authorization_response(body, expected_reactor_id)
    reset_code = body[:reset_code]

    if body[:reactor_id] && body[:reactor_id] != expected_reactor_id
      return { success: false, error: "Reactor ID mismatch", code: reset_code }
    end

    if body[:expires_at] && Time.parse(body[:expires_at].to_s) < Time.current
      return { success: false, error: "Code expired", code: reset_code }
    end

    unless reset_code.match?(/^RST-\d+-\d+-[A-Z0-9]+$/)
      return { success: false, error: "Invalid code format", code: reset_code }
    end

    if body[:authorized_manager] || body[:manager_email]
      return { success: false, error: "Manager mismatch", code: reset_code }
    end

    # If we get here, the code passed all checks.
    { success: true, error: nil, code: reset_code }
  end

  def response_type
    rand(1..4)
  end
end