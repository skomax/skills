---
paths:
  - "**/*.py"
  - "**/*.js"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.sol"
  - "**/*.rb"
  - "**/Dockerfile*"
  - "**/docker-compose*.yml"
  - "**/.env*"
---
# Security Rules

## Mandatory Checks Before Every Commit

- [ ] No hardcoded secrets (API keys, passwords, tokens, private keys)
- [ ] All user inputs validated and sanitized
- [ ] SQL injection prevention (parameterized queries only)
- [ ] XSS prevention (sanitized HTML output, CSP headers)
- [ ] CSRF protection enabled on all state-changing endpoints
- [ ] Authentication/authorization verified on protected routes
- [ ] Rate limiting on all public endpoints
- [ ] Error messages do not leak sensitive data (stack traces, DB schemas, internal paths)

## Secret Management

- NEVER hardcode secrets in source code or Docker images
- Use environment variables loaded from `.env` files (gitignored)
- Provide `.env.example` with placeholder values for documentation
- Validate all required secrets at application startup
- Rotate any secret that may have been exposed immediately
- Use Docker secrets or vault services for production

## Files That Must NEVER Be Committed

```gitignore
.env
.env.*
!.env.example
*.pem
*.key
*_rsa
*.p12
credentials.json
service-account*.json
secrets/
```

## Dependency Security

- Run `npm audit` / `pip-audit` / `safety check` before releases
- Update dependencies with known vulnerabilities immediately
- Pin exact versions in lock files
- Review new dependencies before adding (check maintainership, last update, CVEs)

## Web3/Blockchain Specific

- NEVER log or expose private keys
- Validate all contract addresses before interaction
- Use checksummed addresses
- Implement slippage protection for DEX transactions
- Verify contract source code matches deployed bytecode
- Test on testnet before mainnet

## API Security

- Use HTTPS only (redirect HTTP to HTTPS)
- Implement proper CORS configuration (no wildcard in production)
- Use Bearer token authentication with short-lived JWTs
- Implement request size limits
- Log security events (failed auth, rate limit hits, suspicious patterns)

## Security Response Protocol

If a security issue is found:
1. STOP current work immediately
2. Assess severity (CRITICAL / HIGH / MEDIUM / LOW)
3. Fix CRITICAL issues before ANY other work
4. Rotate any potentially exposed secrets
5. Review entire codebase for similar patterns
6. Document the issue and fix in security log
