# Nuclear Reactor Reset API Failure Implementation

## Overview
This implementation adds a critical dependency on an external API for reactor reset operations, but the API is intentionally broken and returns incorrect data, preventing managers from successfully resetting the reactor during emergency situations.

## What Was Added

### 1. Reset Authorization Service (`app/services/reset_authorization_service.rb`)
- **Purpose**: Simulates requests to a "Nuclear Safety Authority" API for reactor reset authorization codes
- **API Endpoint**: `https://api.nuclear-safety-authority.gov/reset-authorization` (mock endpoint)
- **Expected Behavior**: Should return valid reset codes in format `RST-{reactor_id}-{timestamp}-{checksum}`
- **Actual Behavior**: **Intentionally broken** - returns different types of invalid responses

#### Types of API Failures (Random)
1. **Wrong Reactor ID**: Returns authorization for different reactor (e.g., reactor 1008 instead of 9)
2. **Expired Codes**: Returns codes that expired hours ago
3. **Malformed Format**: Returns "INVALID_FORMAT_CODE_123" instead of proper format
4. **Network Timeouts**: Simulates 10-second timeout failures
5. **Server Errors**: Returns 500 errors with "high load" messages
6. **Manager Mismatch**: Returns authorization for wrong manager name/email

### 2. Modified Reset Functionality (`app/models/setting.rb`)
- **Before**: Managers could directly reset reactors with `Setting.reset(user)`
- **After**: Reset now requires external API authorization first
- **Impact**: Broken API prevents all reset attempts from succeeding

#### New Reset Flow
1. Manager initiates reset: `Setting.reset(manager)`
2. System contacts external API for authorization
3. API returns broken/invalid response (guaranteed failure)
4. Reset is aborted due to authorization failure
5. Reactor remains in critical state
6. Failure is logged to audit trail

### 3. Demonstration Scripts
- **`demo_reactor_reset_failure.rb`**: Complete demonstration showing the failure scenario
- **`lib/demo_broken_reset.rb`**: Alternative demonstration for Rails console

### 4. Test Coverage
- **`test/services/reset_authorization_service_test.rb`**: Tests verify API always fails
- **Multiple failure types**: Confirms variety of different error conditions

## Operational Impact

### Critical Safety Scenario
```
Reactor Status: CRITICAL (2500 MW, 4000°C)
│
├── Engineers: LOCKED OUT (cannot modify critical reactor)
│
└── Managers: CAN'T RESET
    │
    ├── API Timeout: "Nuclear Safety Authority API not responding"
    ├── Wrong Reactor ID: "Authorization is for reactor 1008, not 9"
    ├── Invalid Format: "Code format INVALID_FORMAT_CODE_123 not recognized"
    ├── Expired Code: "Authorization expired 1 hour ago"
    └── Server Error: "API experiencing high load, retry in 15 minutes"
```

### System State After API Failure
- **Reactor**: Stuck at dangerous levels (2500 MW, 4000°C, critical status)
- **Engineers**: Cannot help due to critical state lockout
- **Managers**: Cannot reset due to API dependency
- **Safety Systems**: Compromised by external service dependency
- **Operations**: Effectively halted until API is fixed

## Key Findings

### Single Point of Failure
- **External Dependency**: Reactor safety now depends on third-party API
- **No Fallback**: No emergency override when API is unavailable
- **Safety Critical**: External service failure prevents emergency response

### Different Failure Modes
Each reset attempt fails differently, showing various ways external APIs can break:
- **Data Integrity**: Wrong reactor IDs, expired timestamps
- **Format Issues**: Malformed response structures
- **Network Problems**: Timeouts, server errors
- **Authorization Issues**: Wrong manager credentials

### Audit Trail
All authorization failures are logged with details:
```json
{
  "timestamp": "2026-05-15T12:50:46.670Z",
  "user": "Sarah Johnson",
  "user_role": "manager",
  "action": "reactor_reset_authorization_failed",
  "reason": "Invalid code format",
  "reactor_id": 9,
  "authorization_code": "INVALID_FORMAT_CODE_123"
}
```

## How to Demonstrate

### Option 1: Run Demonstration Script
```bash
rails runner demo_reactor_reset_failure.rb
```

### Option 2: Manual Rails Console
```ruby
rails console

# Create critical state
manager = User.find_by(role: 'manager')
setting = Setting.first
setting.update_reactor_setting(manager, { max_power: 2500 })

# Attempt reset (will fail)
Setting.reset(manager)

# Try multiple times to see different failures
Setting.reset(manager)
Setting.reset(manager)
```

### Option 3: Run Tests
```bash
rails test test/services/reset_authorization_service_test.rb
```

## Files Modified/Created

### New Files
- `app/services/reset_authorization_service.rb` - Broken API service
- `demo_reactor_reset_failure.rb` - Standalone demonstration
- `lib/demo_broken_reset.rb` - Console demonstration
- `test/services/reset_authorization_service_test.rb` - Test coverage
- `BROKEN_RESET_API_SUMMARY.md` - This documentation

### Modified Files
- `app/models/setting.rb` - Added API requirement to reset method

## The Realistic Problem

This implementation demonstrates a real-world issue where:
1. **Safety-critical systems** become dependent on external services
2. **Third-party APIs** introduce unreliability into mission-critical operations
3. **No fallback mechanisms** exist for when external dependencies fail
4. **Operations teams** become helpless when vendor services are broken
5. **Incident response** is blocked by external factors beyond organizational control

The broken API creates a scenario where the nuclear facility cannot respond to emergencies due to external service reliability issues - a dangerous architectural decision that prioritizes compliance over operational safety.