# Security Model

## Branch Protection Strategy

### Main Branch Protection

The main branch uses the following protection configuration:

```yaml
enforce_admins: false
```

### Access Control

| Role | Direct Push to Main | Bypass Protection |
|------|---------------------|-------------------|
| Owner | ✅ Allowed | ✅ Yes |
| Collaborators | ❌ Blocked | ❌ No |
| Machine Users | ❌ Blocked | ❌ No |

### Security Implications

**Advantages:**
- Owner retains emergency access for critical fixes
- Collaborators and bots cannot bypass PR workflow
- Maintains standard security for non-admin users

**Trade-offs:**
- Owner can accidentally push without review
- Relies on owner discipline for using bypass responsibly

### Recommended Usage

- **Default workflow**: All changes via pull requests (including owner)
- **Owner bypass**: Reserved for emergencies, hotfixes, or administrative tasks only
- **Regular commits**: Should go through standard PR review process
