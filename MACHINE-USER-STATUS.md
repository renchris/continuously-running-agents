# Machine User Status

## Current Configuration

The repository uses branch protection with `enforce_admins: false` on the main branch.

## Behavior

- **Owner**: Can push directly to main, bypassing branch protection rules
- **Collaborators**: Blocked from pushing to main by branch protection rules
- **Machine Users/Bots**: Blocked from pushing to main (treated as collaborators)

## Use Case

This configuration enables the repository owner to perform administrative tasks (emergency fixes, releases) while maintaining protection against unauthorized pushes from all other users.
