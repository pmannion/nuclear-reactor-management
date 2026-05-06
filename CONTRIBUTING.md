# Contributing to Nuclear Reactor Management System

## Development Guidelines

### Code Quality

This project maintains high standards for code quality and security:

- **Security First**: All code changes must maintain security boundaries and role-based access controls
- **Test Coverage**: New features require comprehensive test coverage
- **Code Style**: Follow Ruby and Rails best practices using RuboCop

### Testing

Run the full test suite before submitting changes:

```bash
# Run all tests
bundle exec rails test

# Run security scan
bin/brakeman

# Check code style
bin/rubocop
```

### Branch Naming

Use descriptive branch names:
- `feature/description-of-feature`
- `bugfix/issue-description`
- `security/vulnerability-fix`

### Pull Request Process

1. **Create Feature Branch**: Branch from `main`
2. **Make Changes**: Implement your changes with tests
3. **Run Tests**: Ensure all tests pass
4. **Security Review**: Verify no security boundaries are compromised
5. **Submit PR**: Include clear description of changes

### Security Considerations

⚠️ **Critical**: This application manages nuclear reactor operations. Any changes must:

- Maintain role-based access controls (Engineers, Interns, Managers)
- Preserve safety thresholds and automatic responses
- Keep audit logging intact
- Not bypass emergency protocols

### Code Review Checklist

- [ ] Tests pass locally
- [ ] Security scan passes (Brakeman)
- [ ] Code style follows RuboCop rules
- [ ] Role permissions remain intact
- [ ] Safety thresholds preserved
- [ ] Audit logging functional

## Getting Help

For questions about:
- **Development Setup**: See README.md
- **Security Concerns**: Contact project maintainers
- **Testing Issues**: Run `SystemCheck.run_reactor_test` for diagnostics