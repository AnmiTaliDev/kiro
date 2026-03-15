# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.x     | ✓         |

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not** open a public issue.

Instead, report it privately via one of these channels:

- **GitHub:** Use [GitHub's private vulnerability reporting](https://github.com/AnmiTaliDev/kiro/security/advisories/new)
- **Email:** anmitalidev@nuros.org

Please include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You can expect an initial response within **72 hours** and a fix within **14 days** for confirmed issues.

## Scope

Security issues relevant to Kiro include:

- Arbitrary command execution via crafted terminal output
- Privilege escalation through shell spawning logic
- Path traversal in drag-and-drop file handling
- URL handler injection via terminal hyperlinks
