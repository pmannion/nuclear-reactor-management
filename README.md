# Nuclear Reactor Management System - Security Interview Challenge

A Rails application for managing nuclear reactor operations with role-based access controls and safety monitoring.

## Quick Start

### Prerequisites
- Ruby 3.2.0 (see `.ruby-version`)
- Rails 7.1+
- SQLite3

### Development Setup

1. **Clone and setup**:
   ```bash
   git clone https://github.com/pmannion/nuclear-reactor-management.git
   cd nuclear-reactor-management
   bundle install
   ```

2. **Database setup**:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Run tests**:
   ```bash
   bundle exec rails test
   ```

4. **Start the application**:
   ```bash
   rails console
   ```

### Docker Support

Build and run with Docker:
```bash
docker build -t nuclear-reactor-management .
docker run -it nuclear-reactor-management rails console
```

### Role Permissions

**Engineers** - Primary reactor operators with full operational permissions:
- Create, update, and delete reactor settings during normal operations
- Monitor all reactor parameters and safety systems
- Cannot modify reactor settings when system is in critical state
- Must contact manager for reset authorization during emergencies

**Interns** - Training personnel with restricted access:
- Read-only access to reactor parameters for learning purposes
- Should NOT have modification permissions for safety reasons
- Can observe system operations and run status checks

**Managers** - Senior oversight with specialized emergency authority:
- **Reactor Reset Authority**: Only managers can reset the reactor from critical state
- **Daily Maintenance Operations**: Exclusive responsibility for performing daily maintenance cycles
- Emergency shutdown and safety override capabilities
- Full audit trail access for incident investigation

## Reactor Safety Rules and Parameters

### Critical Power Thresholds
- **Safe Operating Range**: 150-2000 MW
- **Critical Threshold**: Max power > 2000 MW automatically triggers critical state
- **Emergency Response**: When critical threshold exceeded, temperature spikes to 4000°C and status changes to "critical"

### Temperature Operating Limits
- **Normal Range**: 650-1000°C
- **Elevated Warning**: 1000-3000°C (requires monitoring)
- **Critical Danger**: > 3000°C (immediate intervention required)
- **Emergency Levels**: 4000°C (automatic critical state activation)

### System Status States
- **Normal**: Standard operations, all parameters within safe limits
- **Maintenance**: Scheduled maintenance mode, limited operations
- **Critical**: Emergency state requiring immediate manager intervention

## Manager Maintenance Mode Responsibilities

### Daily Maintenance Operations
Managers must perform daily maintenance to ensure reactor safety:

```bash
rails console
manager = User.find_by(email: 'manager@nuclear.com')
manager.perform_daily_maintenance
```

**Maintenance Effects**:
- Temporarily sets reactor to maintenance mode
- Prevents temperature drift and system degradation
- Updates maintenance timestamp for compliance tracking
- **Critical**: Overdue maintenance causes temperature spikes above safe levels

### Maintenance Status Monitoring
Check if maintenance is overdue:
```bash
Setting.check_maintenance_status
```

## Critical Reactor Status Emergency Protocol

### When Reactor Enters Critical State

**⚠️ IMMEDIATE ACTIONS REQUIRED:**

1. **Engineer Access Restricted**: Engineers cannot modify settings during critical state
2. **Manager Authorization Required**: Only managers can perform reactor reset
3. **Contact Procedure**: Engineers must immediately contact manager for reset authorization

### Manager Reset Procedure

When reactor is in critical state, managers must execute emergency reset:

```bash
rails console
manager = User.find_by(email: 'manager@nuclear.com')
manager.reset_reactor
```

**Reset Actions**:
- Restores max_power to safe level (1200 MW)
- Reduces temperature to manageable level (800°C)
- Changes status from "critical" back to "normal"
- Allows engineers to resume normal operations

### Emergency Contacts
- **Critical State**: Contact Bob Manager immediately
- **Maintenance Overdue**: Schedule daily maintenance with manager
- **System Anomalies**: Run `SystemCheck.run_reactor_test` and report findings



## Useful Reactor Change Logs

Check the reactor logs at `log/reactor_settings.log`.


## System Status Check

The `SystemCheck` class provides comprehensive reactor monitoring with the `run_reactor_test` method:

```bash


rails console
SystemCheck.run_reactor_test


```

The system check provides detailed output including:
- ⚙️ Current reactor parameters and safety status
- 🛡️ Safety analysis with threshold checks
- 🚨 Security violation detection
- 📝 Recent activity timeline with flags
- 🔒 Comprehensive security assessment
- ✅/❌ Overall safety verdict

## Testing via Rails Console

All reactor management is done through Rails console methods. Test the vulnerabilities:

```bash
rails console

# Test 1: Run system check first
SystemCheck.run_reactor_test



## Business Logic

The system has automatic safety responses:
- If `max_power > 2000`: sets `temperature = 4000` and `status = 'critical'`
- All changes are logged to `log/reactor_settings.log`


## Console-Only Operation

This system operates entirely through Rails console for enhanced security. No web interface is available.

```bash
rails console
```


## Log Analysis

The application generates comprehensive audit logs showing:
- Timestamp of each change
- User who made the change
- User's role
- Exact field changes (before/after values)
