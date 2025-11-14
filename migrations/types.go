package main

import "time"

// Migration represents a single migration with up and down operations
type Migration struct {
	Version     int       `json:"version"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	AppliedAt   time.Time `json:"applied_at,omitempty"`
	Up          []Command `json:"-"`
	Down        []Command `json:"-"`
}

// Command represents a Terraform state operation
type Command struct {
	Type        string   `json:"type"`        // mv, rm, import
	Description string   `json:"description"` // Human-readable description
	Args        []string `json:"args"`        // Command arguments
}

// MigrationState tracks applied migrations
type MigrationState struct {
	Applied []Migration `json:"applied"`
}

// CommandType represents the type of Terraform state operation
type CommandType string

const (
	// CommandTypeMove moves a resource from one address to another
	CommandTypeMove CommandType = "mv"
	// CommandTypeRemove removes a resource from state
	CommandTypeRemove CommandType = "rm"
	// CommandTypeImport imports an existing resource into state
	CommandTypeImport CommandType = "import"
)

// MigrationDirection represents the direction of migration
type MigrationDirection string

const (
	// DirectionUp applies the migration
	DirectionUp MigrationDirection = "up"
	// DirectionDown rolls back the migration
	DirectionDown MigrationDirection = "down"
)

// MigrationStatus represents the status of a migration
type MigrationStatus string

const (
	// StatusApplied indicates the migration has been applied
	StatusApplied MigrationStatus = "applied"
	// StatusPending indicates the migration has not been applied
	StatusPending MigrationStatus = "pending"
)

// MigrationConfig holds configuration for the migration system
type MigrationConfig struct {
	StateFile     string
	MigrationsDir string
	BackupDir     string
}

// MigrationResult holds the result of a migration operation
type MigrationResult struct {
	Success   bool
	Migration Migration
	Error     error
	Duration  time.Duration
}

// NewMigration creates a new Migration instance
func NewMigration(version int, name, description string) Migration {
	return Migration{
		Version:     version,
		Name:        name,
		Description: description,
		Up:          []Command{},
		Down:        []Command{},
	}
}

// AddUpCommand adds a command to the Up operations
func (m *Migration) AddUpCommand(cmdType CommandType, description string, args ...string) {
	m.Up = append(m.Up, Command{
		Type:        string(cmdType),
		Description: description,
		Args:        args,
	})
}

// AddDownCommand adds a command to the Down operations
func (m *Migration) AddDownCommand(cmdType CommandType, description string, args ...string) {
	m.Down = append(m.Down, Command{
		Type:        string(cmdType),
		Description: description,
		Args:        args,
	})
}

// IsApplied checks if a migration has been applied
func (m *Migration) IsApplied() bool {
	return !m.AppliedAt.IsZero()
}

// MarkApplied marks the migration as applied
func (m *Migration) MarkApplied() {
	m.AppliedAt = time.Now()
}
