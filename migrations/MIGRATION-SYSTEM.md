# Migration System Summary

## What Changed

The Terraform state migration system has been moved from a single bash script to a professional Go-based system with database-style up/down migrations.

## Key Improvements

### Before (Bash Script)
- Single `migrate-state.sh` file with interactive menu
- Manual operations, no tracking
- No version control
- No rollback capability
- Operations had to be run interactively

### After (Go-based System)
- ✅ **Structured migrations** in `migrations/` directory
- ✅ **Up/Down migrations** - Apply and rollback changes
- ✅ **Version tracking** - Know exactly which migrations have been applied
- ✅ **Automatic backups** - State is backed up before each migration
- ✅ **Declarative syntax** - Easy-to-read migration files
- ✅ **CI/CD friendly** - Can be automated
- ✅ **Better error handling** - Clear error messages and recovery

## New Directory Structure

```
kubernetes-stack/
├── migrations/              # New migration system
│   ├── main.go             # Migration tool implementation
│   ├── go.mod              # Go dependencies
│   ├── migrate             # Compiled binary
│   ├── .migration_state.json  # Tracks applied migrations
│   ├── README.md           # Comprehensive documentation
│   └── files/              # Migration files
│       └── 0001_*.go       # Individual migrations (versioned)
├── migrate.sh              # Convenience wrapper script
├── Makefile                # Make commands for common tasks
└── migrate-state.sh        # Old bash script (deprecated)
```

## Quick Start

### Using the Wrapper Script
```bash
# Check current status
./migrate.sh status

# Apply all pending migrations
./migrate.sh up

# Rollback last migration
./migrate.sh down

# Create new migration
./migrate.sh create my_migration_name
```

### Using Make
```bash
# Show available commands
make help

# Check migration status
make migrate-status

# Apply migrations
make migrate-up

# Rollback migrations
make migrate-down

# Create new migration
make migrate-create NAME=my_migration
```

### Direct Binary Usage
```bash
cd migrations
./migrate status
./migrate up
./migrate down
./migrate create migration_name
```

## Migration File Structure

Each migration is a Go file with up and down operations:

```go
package main

func Migration0001() Migration {
	return Migration{
		Version:     1,
		Name:        "move_account_alias_to_iam_module",
		Description: "Moves the standalone account alias resource",
		Up: []Command{
			{
				Type:        "mv",
				Description: "Move account alias to IAM module",
				Args:        []string{
					"aws_iam_account_alias.alias",
					"module.iam.aws_iam_account_alias.alias[0]",
				},
			},
		},
		Down: []Command{
			{
				Type:        "mv",
				Description: "Move account alias back to root",
				Args:        []string{
					"module.iam.aws_iam_account_alias.alias[0]",
					"aws_iam_account_alias.alias",
				},
			},
		},
	}
}
```

## Command Types

### Move (mv)
Move a resource to a new address:
- Useful for refactoring into modules
- Renaming resources
- No resource destruction

### Remove (rm)
Remove a resource from state:
- Stop managing a resource
- Clean up orphaned state entries

### Import
Import existing AWS resources:
- Bring unmanaged resources under Terraform
- Recover from state loss

## Workflow Example

### 1. Create a Migration
```bash
./migrate.sh create move_vpc_to_module
```

This creates `migrations/files/0002_move_vpc_to_module.go`

### 2. Edit the Migration
```go
package main

func Migration0002() Migration {
	return Migration{
		Version:     2,
		Name:        "move_vpc_to_module",
		Description: "Move VPC resource into dedicated module",
		Up: []Command{
			{
				Type:        "mv",
				Description: "Move VPC to network module",
				Args:        []string{"aws_vpc.main", "module.network.aws_vpc.main"},
			},
		},
		Down: []Command{
			{
				Type:        "mv",
				Description: "Move VPC back to root",
				Args:        []string{"module.network.aws_vpc.main", "aws_vpc.main"},
			},
		},
	}
}
```

### 3. Check Status
```bash
./migrate.sh status
```

Output:
```
Version   Name                      Status      Applied At
------------------------------------------------------------
0001      move_account_alias...     ✓ Applied   2025-11-14 10:30:00
0002      move_vpc_to_module        ⧗ Pending   -
```

### 4. Apply Migration
```bash
./migrate.sh up
```

### 5. Verify
```bash
terraform plan
```

Should show no changes if migration was successful.

### 6. Rollback if Needed
```bash
./migrate.sh down
```

## State Tracking

The system tracks migrations in `.migration_state.json`:

```json
{
  "applied": [
    {
      "version": 1,
      "name": "move_account_alias_to_iam_module",
      "description": "Moves the standalone account alias resource",
      "applied_at": "2025-11-14T10:30:00Z"
    }
  ]
}
```

This file is automatically managed and should be committed to version control.

## Safety Features

1. **Automatic Backups**: State is backed up before each migration
   - Files named: `terraform.tfstate.backup_YYYYMMDD_HHMMSS`

2. **Version Tracking**: Prevents accidental re-runs
   - Each migration runs exactly once

3. **Confirmation Prompts**: For destructive operations
   - Reset command requires explicit confirmation

4. **Clear Status**: Color-coded output
   - 🟢 Green = Applied
   - 🟡 Yellow = Pending
   - 🔴 Red = Errors

5. **Rollback Capability**: Undo migrations
   - Down migrations reverse changes

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Apply Migrations
on:
  push:
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Build Migration Tool
        run: make build

      - name: Apply Migrations
        run: ./migrate.sh up

      - name: Verify No Changes
        run: terraform plan -detailed-exitcode
```

## Best Practices

1. **Test First**: Always test migrations in non-production
2. **Small Steps**: Keep migrations focused and small
3. **Descriptive Names**: Use clear, meaningful names
4. **Document Why**: Add descriptions explaining the change
5. **Version Control**: Commit migrations before applying
6. **Verify**: Run `terraform plan` after migrations
7. **Backup**: Keep manual backups of important states
8. **Reversible**: Always implement down migrations

## Common Scenarios

### Moving to Module
```go
Up: []Command{
	{Type: "mv", Args: []string{"aws_vpc.main", "module.network.aws_vpc.main"}},
}
Down: []Command{
	{Type: "mv", Args: []string{"module.network.aws_vpc.main", "aws_vpc.main"}},
}
```

### Importing Existing Resource
```go
Up: []Command{
	{Type: "import", Args: []string{"aws_s3_bucket.logs", "my-logs-bucket"}},
}
Down: []Command{
	{Type: "rm", Args: []string{"aws_s3_bucket.logs"}},
}
```

### Removing Deprecated Resource
```go
Up: []Command{
	{Type: "rm", Args: []string{"aws_instance.old_server"}},
}
Down: []Command{
	{Type: "import", Args: []string{"aws_instance.old_server", "i-1234567890"}},
}
```

## Troubleshooting

### Migration Failed
1. Check error message
2. Manually fix state if needed
3. Update migration file
4. Re-run or rollback

### State Out of Sync
```bash
# Reset tracking (doesn't undo migrations)
./migrate.sh reset

# Or manually edit .migration_state.json
```

### Need to Skip a Migration
Edit `.migration_state.json` to mark migration as applied without running it.

## Documentation

- **migrations/README.md** - Comprehensive migration system documentation
- **STATE-MIGRATION.md** - Migration guide with old bash script reference
- **README.md** - Project overview with migration quick start

## Old System (migrate-state.sh)

The old bash-based script is preserved for reference but is deprecated. It provided:
- Interactive menu for state operations
- One-off commands
- No version tracking
- No rollback capability

Use the new Go-based system for all new work.
