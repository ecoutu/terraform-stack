# Go Types Documentation

## Overview

The migration system uses a well-defined type system in `types.go` for type safety and better code organization.

## Core Types

### Migration

Represents a single migration with up and down operations.

```go
type Migration struct {
    Version     int       `json:"version"`
    Name        string    `json:"name"`
    Description string    `json:"description"`
    AppliedAt   time.Time `json:"applied_at,omitempty"`
    Up          []Command `json:"-"`
    Down        []Command `json:"-"`
}
```

### Command

Represents a Terraform state operation.

```go
type Command struct {
    Type        string   `json:"type"`
    Description string   `json:"description"`
    Args        []string `json:"args"`
}
```

### MigrationState

Tracks applied migrations.

```go
type MigrationState struct {
    Applied []Migration `json:"applied"`
}
```

## Type-Safe Constants

### CommandType

```go
type CommandType string

const (
    CommandTypeMove   CommandType = "mv"     // Move resource
    CommandTypeRemove CommandType = "rm"     // Remove from state
    CommandTypeImport CommandType = "import" // Import existing resource
)
```

### MigrationDirection

```go
type MigrationDirection string

const (
    DirectionUp   MigrationDirection = "up"
    DirectionDown MigrationDirection = "down"
)
```

### MigrationStatus

```go
type MigrationStatus string

const (
    StatusApplied MigrationStatus = "applied"
    StatusPending MigrationStatus = "pending"
)
```

## Helper Functions

### NewMigration

Creates a new Migration instance.

```go
func NewMigration(version int, name, description string) Migration
```

**Example:**
```go
m := NewMigration(
    1,
    "move_resource_to_module",
    "Moves the resource into a module",
)
```

### AddUpCommand

Adds a command to the Up operations.

```go
func (m *Migration) AddUpCommand(cmdType CommandType, description string, args ...string)
```

**Example:**
```go
m.AddUpCommand(
    CommandTypeMove,
    "Move VPC to network module",
    "aws_vpc.main",
    "module.network.aws_vpc.main",
)
```

### AddDownCommand

Adds a command to the Down operations.

```go
func (m *Migration) AddDownCommand(cmdType CommandType, description string, args ...string)
```

**Example:**
```go
m.AddDownCommand(
    CommandTypeMove,
    "Move VPC back to root",
    "module.network.aws_vpc.main",
    "aws_vpc.main",
)
```

### IsApplied

Checks if a migration has been applied.

```go
func (m *Migration) IsApplied() bool
```

### MarkApplied

Marks the migration as applied.

```go
func (m *Migration) MarkApplied()
```

## Usage Examples

### Type-Safe Migration (Recommended)

```go
package main

func Migration0001() Migration {
    // Create migration with helper
    m := NewMigration(
        1,
        "refactor_networking",
        "Move networking resources to dedicated module",
    )

    // Add up operations using type-safe constants
    m.AddUpCommand(
        CommandTypeMove,
        "Move VPC to network module",
        "aws_vpc.main",
        "module.network.aws_vpc.main",
    )

    m.AddUpCommand(
        CommandTypeMove,
        "Move subnets to network module",
        "aws_subnet.public",
        "module.network.aws_subnet.public",
    )

    // Add down operations for rollback
    m.AddDownCommand(
        CommandTypeMove,
        "Move VPC back to root",
        "module.network.aws_vpc.main",
        "aws_vpc.main",
    )

    m.AddDownCommand(
        CommandTypeMove,
        "Move subnets back to root",
        "module.network.aws_subnet.public",
        "aws_subnet.public",
    )

    return m
}
```

### Traditional Struct Initialization (Still Supported)

```go
package main

func Migration0002() Migration {
    return Migration{
        Version:     2,
        Name:        "import_existing_resources",
        Description: "Import existing AWS resources",
        Up: []Command{
            {
                Type:        string(CommandTypeImport),
                Description: "Import S3 bucket",
                Args:        []string{"aws_s3_bucket.logs", "my-logs-bucket"},
            },
        },
        Down: []Command{
            {
                Type:        string(CommandTypeRemove),
                Description: "Remove S3 bucket from state",
                Args:        []string{"aws_s3_bucket.logs"},
            },
        },
    }
}
```

### All Command Types

```go
func Migration0003() Migration {
    m := NewMigration(3, "comprehensive_example", "Shows all command types")

    // Move resource
    m.AddUpCommand(
        CommandTypeMove,
        "Move resource to module",
        "aws_instance.web",
        "module.compute.aws_instance.web",
    )

    // Remove resource from state
    m.AddUpCommand(
        CommandTypeRemove,
        "Remove deprecated resource",
        "aws_instance.old_server",
    )

    // Import existing resource
    m.AddUpCommand(
        CommandTypeImport,
        "Import existing RDS instance",
        "aws_db_instance.main",
        "my-database-instance",
    )

    // Corresponding down operations
    m.AddDownCommand(
        CommandTypeMove,
        "Move resource back",
        "module.compute.aws_instance.web",
        "aws_instance.web",
    )

    m.AddDownCommand(
        CommandTypeImport,
        "Re-import old server (if needed)",
        "aws_instance.old_server",
        "i-1234567890abcdef0",
    )

    m.AddDownCommand(
        CommandTypeRemove,
        "Remove imported RDS instance",
        "aws_db_instance.main",
    )

    return m
}
```

## Benefits of Type-Safe Approach

1. **Compile-Time Safety**: Catch errors at build time, not runtime
2. **IDE Support**: Better autocomplete and type hints
3. **Cleaner Code**: More readable and maintainable
4. **Less Error-Prone**: Can't use invalid command types
5. **Backward Compatible**: Old struct initialization still works

## Migration Template

When you create a new migration with `./migrate.sh create <name>`, the generated file uses the type-safe approach:

```go
package main

// Migration0004 - my_migration_name
func Migration0004() Migration {
    // Create a new migration using the helper function
    m := NewMigration(
        4,
        "my_migration_name",
        "Description of what this migration does",
    )

    // Add your up operations here
    // m.AddUpCommand(
    //     CommandTypeMove,
    //     "Description",
    //     "source",
    //     "destination",
    // )

    // Add down operations to reverse the changes
    // m.AddDownCommand(
    //     CommandTypeMove,
    //     "Description",
    //     "destination",
    //     "source",
    // )

    return m
}
```

## Best Practices

1. **Use Type-Safe Constants**: Always use `CommandTypeMove`, `CommandTypeRemove`, `CommandTypeImport`
2. **Use Helper Functions**: Prefer `NewMigration()` and `AddUpCommand()` methods
3. **Descriptive Names**: Use clear command descriptions
4. **Symmetric Operations**: Down should reverse what Up does
5. **Test Migrations**: Always test both up and down operations

## Type Checking

The Go compiler ensures type safety:

```go
// ✅ Correct - using constant
m.AddUpCommand(CommandTypeMove, "Move resource", "source", "dest")

// ❌ Compile error - typo caught at build time
m.AddUpCommand("move", "Move resource", "source", "dest")
// Error: cannot use "move" (type string) as type CommandType

// ✅ Correct - explicit conversion if needed
m.AddUpCommand(CommandType("mv"), "Move resource", "source", "dest")
```

## Future Enhancements

The type system is designed to be extensible for future features:

- Additional command types (e.g., `CommandTypeReplace`)
- Migration dependencies and ordering
- Conditional execution
- Dry-run mode
- Migration validation
