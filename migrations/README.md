# Terraform State Migrations

This directory contains a migration system for managing Terraform state changes, similar to database migration tools.

## Overview

The migration system uses Go to provide a structured, versioned approach to state management with:
- **Up/Down migrations**: Apply or rollback changes
- **Version tracking**: Know exactly which migrations have been applied
- **Automatic backups**: State is backed up before each migration
- **Declarative syntax**: Easy-to-read migration files

## Installation

Build the migration tool:

```bash
cd migrations
go build -o migrate .
```

Or from the project root:
```bash
make build
```

## Usage

### Create a New Migration

```bash
./migrate create move_vpc_to_module
```

This creates a new migration file in `migrations/` directory with the next version number.
Each migration is a separate Go file that automatically registers itself.

### Apply Migrations

Apply all pending migrations:
```bash
./migrate up
```

Apply next N migrations:
```bash
./migrate up 2
```

### Rollback Migrations

Rollback last migration:
```bash
./migrate down
```

Rollback last N migrations:
```bash
./migrate down 3
```

### Check Status

View migration status:
```bash
./migrate status
```

Check current version:
```bash
./migrate version
```

### Reset (Danger!)

Reset all migration tracking (doesn't undo migrations):
```bash
./migrate reset
```

## Migration File Structure

Each migration is stored in its own file (e.g., `0001_migration_name.go`) in the `migrations/` directory.
The file contains the migration function and an `init()` function that automatically registers it.

### Standard Structure

```go
package main

// Migration0001 - move_account_alias_to_iam_module
func Migration0001() Migration {
	// Create migration with helper function
	m := NewMigration(
		1,
		"move_account_alias_to_iam_module",
		"Moves the standalone account alias resource into the IAM module",
	)

	// Add up operations using type-safe constants
	m.AddUpCommand(
		CommandTypeMove,
		"Move account alias to IAM module",
		"aws_iam_account_alias.alias",
		"module.iam.aws_iam_account_alias.alias[0]",
	)

	// Add down operations for rollback
	m.AddDownCommand(
		CommandTypeMove,
		"Move account alias back to root module",
		"module.iam.aws_iam_account_alias.alias[0]",
		"aws_iam_account_alias.alias",
	)

	return m
}

// This init function automatically registers the migration
// No manual registration needed!
func init() {
	registerMigration(1, Migration0001)
}
```

See [TYPES.md](TYPES.md) for complete type system documentation.

### Alternative: Traditional Struct Approach

```go
package main

// Migration0001 - migration_name
func Migration0001() Migration {
	return Migration{
		Version:     1,
		Name:        "move_account_alias_to_iam_module",
		Description: "Moves the standalone account alias resource into the IAM module",
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
				Description: "Move account alias back to root module",
				Args:        []string{
					"module.iam.aws_iam_account_alias.alias[0]",
					"aws_iam_account_alias.alias",
				},
			},
		},
	}
}

func init() {
	registerMigration(1, Migration0001)
}
```

## Command Types

The migration system provides type-safe constants for all command types:

### Move (CommandTypeMove)
Move a resource to a new address:
```go
// Type-safe approach
m.AddUpCommand(
	CommandTypeMove,
	"Move resource to module",
	"source_address",
	"destination_address",
)

// Traditional approach
{
	Type: "mv",
	Description: "Move resource to module",
	Args: []string{"source_address", "destination_address"},
}
```

### Remove (CommandTypeRemove)
Remove a resource from state:
```go
// Type-safe approach
m.AddUpCommand(
	CommandTypeRemove,
	"Remove deprecated resource",
	"resource_address",
)

// Traditional approach
{
	Type: "rm",
	Description: "Remove deprecated resource",
	Args: []string{"resource_address"},
}
```

### Import (CommandTypeImport)
Import an existing resource:
```go
// Type-safe approach
m.AddUpCommand(
	CommandTypeImport,
	"Import existing S3 bucket",
	"aws_s3_bucket.example",
	"my-bucket-name",
)

// Traditional approach
{
	Type: "import",
	Description: "Import existing S3 bucket",
	Args: []string{"aws_s3_bucket.example", "my-bucket-name"},
}
```

For complete type documentation, see [TYPES.md](TYPES.md).

## Migration State

Migration state is tracked in `.migration_state.json`:

```json
{
  "applied": [
    {
      "version": 1,
      "name": "move_account_alias_to_iam_module",
      "description": "Moves the standalone account alias resource into the IAM module",
      "applied_at": "2025-11-14T10:30:00Z"
    }
  ]
}
```

## Best Practices

1. **Test First**: Always test migrations in a non-production environment
2. **Small Steps**: Keep migrations small and focused
3. **Descriptive Names**: Use clear, descriptive migration names
4. **Document**: Add descriptions explaining what and why
5. **Verify**: Run `terraform plan` after migrations to verify no changes
6. **Backup**: Automatic backups are created, but keep your own too
7. **Reversible**: Always implement down migrations

## Common Scenarios

### Moving Resource to Module

```go
Up: []Command{
	{
		Type: "mv",
		Args: []string{"aws_vpc.main", "module.network.aws_vpc.main"},
	},
},
Down: []Command{
	{
		Type: "mv",
		Args: []string{"module.network.aws_vpc.main", "aws_vpc.main"},
	},
},
```

### Importing Existing Resource

```go
Up: []Command{
	{
		Type: "import",
		Args: []string{"aws_s3_bucket.logs", "my-logs-bucket-12345"},
	},
},
Down: []Command{
	{
		Type: "rm",
		Args: []string{"aws_s3_bucket.logs"},
	},
},
```

### Removing Deprecated Resource

```go
Up: []Command{
	{
		Type: "rm",
		Args: []string{"aws_instance.old_server"},
	},
},
Down: []Command{
	{
		Type: "import",
		Args: []string{"aws_instance.old_server", "i-1234567890abcdef0"},
	},
},
```

## Workflow Example

1. **Create migration:**
   ```bash
   ./migrate create add_new_module
   ```

2. **Edit the migration file** in `migrations/` directory (e.g., `migrations/0002_add_new_module.go`)

3. **Rebuild the tool:**
   ```bash
   make build
   ```

4. **Check status:**
   ```bash
   ./migrate status
   ```

5. **Apply migration:**
   ```bash
   ./migrate up
   ```

6. **Verify no changes:**
   ```bash
   cd .. && terraform plan
   ```

6. **If there's an issue, rollback:**
   ```bash
   ./migrate down
   ```

## Directory Structure

```
migrations/
├── main.go                  # Main migration tool
├── types.go                 # Type definitions
├── go.mod                   # Go module file
├── .migration_state.json    # Migration state tracking
├── 0001_*.go                # Individual migration files
├── 0002_*.go                # Each migration in its own file
└── files/                   # (deprecated, kept for reference)
```

**Note:** Each migration is now a separate `.go` file in the `migrations/` directory.
The `files/` subdirectory is deprecated but kept for backward compatibility.

## Safety Features

- ✅ Automatic state backups before migrations
- ✅ Version tracking prevents accidental re-runs
- ✅ Confirmation prompts for destructive operations
- ✅ Clear status reporting
- ✅ Rollback capability
- ✅ Color-coded output for clarity

## Troubleshooting

### Migration Failed Mid-Way

1. Check the error message
2. Manually fix the state if needed
3. Update the migration file
4. Re-run or rollback

### State Out of Sync

```bash
# Reset migration tracking (doesn't undo migrations)
./migrate reset

# Or manually edit .migration_state.json
```

### Need to Skip a Migration

Remove it from `.migration_state.json` applied list, or use terraform state commands directly.

## Integration with CI/CD

```yaml
# Example GitHub Actions workflow
- name: Run Migrations
  run: |
    cd migrations
    go build -o migrate .
    ./migrate up
    cd ..
    terraform plan -detailed-exitcode
```
