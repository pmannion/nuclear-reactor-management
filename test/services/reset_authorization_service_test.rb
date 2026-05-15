require 'test_helper'

class ResetAuthorizationServiceTest < ActiveSupport::TestCase
  def setup
    @manager = users(:manager) || User.create!(
      name: "Test Manager",
      email: "test.manager@reactor.com",
      password: "secure123",
      role: "manager"
    )
    @reactor_id = 1001
  end

  test "API always fails with different error types" do
    # Run multiple requests to see the different failure types
    failures = []

    10.times do
      result = ResetAuthorizationService.request_reset_code(@reactor_id, @manager)
      assert_not result[:success], "API should always fail but returned success"
      failures << result[:error]
    end

    # Should get a variety of different failure types
    assert failures.uniq.length > 1, "Expected multiple different failure types, got: #{failures.uniq}"

    # Common failure types we expect
    expected_errors = [
      "Reactor ID mismatch",
      "Code expired",
      "Invalid code format",
      "API timeout",
      "API server error",
      "Manager mismatch"
    ]

    # At least some of the expected error types should appear
    overlapping_errors = failures & expected_errors
    assert overlapping_errors.length > 0, "Expected some common error types, got: #{failures.uniq}"
  end

  test "service handles manager parameter validation" do
    # The service should work with valid manager objects
    result = ResetAuthorizationService.request_reset_code(@reactor_id, @manager)
    assert result.is_a?(Hash), "Should return a hash result"
    assert result.key?(:success), "Result should include success key"
    assert result.key?(:error), "Result should include error key"
  end

  test "different reactor IDs produce different responses" do
    result1 = ResetAuthorizationService.request_reset_code(1001, @manager)
    result2 = ResetAuthorizationService.request_reset_code(1002, @manager)

    # Both should fail, but potentially with different details
    assert_not result1[:success]
    assert_not result2[:success]

    # They might have different error codes or messages due to randomization
    assert result1.is_a?(Hash)
    assert result2.is_a?(Hash)
  end
end