package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	stateFile      = "migrations/.migration_state.json"
	migrationsDir  = "migrations/files"
	colorReset     = "\033[0m"
	colorRed       = "\033[31m"
	colorGreen     = "\033[32m"
	colorYellow    = "\033[33m"
	colorBlue      = "\033[34m"
	colorMagenta   = "\033[35m"
	colorCyan      = "\033[36m"
)

// migrationRegistry stores all registered migrations
var migrationRegistry = make(map[int]func() Migration)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "create":
		if len(os.Args) < 3 {
			fmt.Println("Usage: migrate create <migration_name>")
			os.Exit(1)
		}
		createMigration(os.Args[2])
	case "up":
		steps := 0
		if len(os.Args) > 2 {
			s, err := strconv.Atoi(os.Args[2])
			if err != nil {
				fmt.Printf("Invalid number of steps: %v\n", err)
				os.Exit(1)
			}
			steps = s
		}
		migrateUp(steps)
	case "down":
		steps := 1
		if len(os.Args) > 2 {
			s, err := strconv.Atoi(os.Args[2])
			if err != nil {
				fmt.Printf("Invalid number of steps: %v\n", err)
				os.Exit(1)
			}
			steps = s
		}
		migrateDown(steps)
	case "status":
		showStatus()
	case "version":
		showVersion()
	case "reset":
		resetMigrations()
	default:
		fmt.Printf("Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(colorCyan + "Terraform State Migration Tool" + colorReset)
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  migrate create <name>    Create a new migration file")
	fmt.Println("  migrate up [n]           Apply next n migrations (default: all)")
	fmt.Println("  migrate down [n]         Rollback last n migrations (default: 1)")
	fmt.Println("  migrate status           Show migration status")
	fmt.Println("  migrate version          Show current migration version")
	fmt.Println("  migrate reset            Reset all migrations (DESTRUCTIVE)")
	fmt.Println("")
}

func createMigration(name string) {
	// Get next version number
	migrations := loadMigrations()
	version := 1
	if len(migrations) > 0 {
		version = migrations[len(migrations)-1].Version + 1
	}

	// Create migration file in migrations directory (not files/)
	filename := fmt.Sprintf("%04d_%s.go", version, sanitizeName(name))
	filepath := fmt.Sprintf("migrations/%s", filename)

	template := fmt.Sprintf(`package main

// Migration%04d - %s
func Migration%04d() Migration {
	// Create a new migration using the helper function
	m := NewMigration(
		%d,
		"%s",
		"Description of what this migration does",
	)

	// Example: Move resource to module
	// m.AddUpCommand(
	// 	CommandTypeMove,
	// 	"Move account alias to IAM module",
	// 	"aws_iam_account_alias.alias",
	// 	"module.iam.aws_iam_account_alias.alias[0]",
	// )

	// Example: Remove resource from state
	// m.AddUpCommand(
	// 	CommandTypeRemove,
	// 	"Remove old resource",
	// 	"aws_iam_user.old_user",
	// )

	// Example: Import existing resource
	// m.AddUpCommand(
	// 	CommandTypeImport,
	// 	"Import existing S3 bucket",
	// 	"aws_s3_bucket.example",
	// 	"my-bucket-name",
	// )

	// Add down operations to reverse the changes
	// m.AddDownCommand(
	// 	CommandTypeMove,
	// 	"Move account alias back to root",
	// 	"module.iam.aws_iam_account_alias.alias[0]",
	// 	"aws_iam_account_alias.alias",
	// )

	return m
}

func init() {
	registerMigration(%d, Migration%04d)
}
`, version, name, version, version, name, version, version)

	err := os.WriteFile(filepath, []byte(template), 0644)
	if err != nil {
		fmt.Printf("%sError creating migration file: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	fmt.Printf("%s✓ Created migration: %s%s\n", colorGreen, filepath, colorReset)
	fmt.Println("\nNext steps:")
	fmt.Println("1. Edit the migration file to add your state operations")
	fmt.Println("2. Rebuild the tool: make build")
	fmt.Println("3. Run 'migrate up' to apply the migration")
}

func sanitizeName(name string) string {
	name = strings.ToLower(name)
	name = strings.ReplaceAll(name, " ", "_")
	return strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '_' {
			return r
		}
		return -1
	}, name)
}

func loadMigrations() []Migration {
	var migrations []Migration

	// Load migrations from the registry
	for version, migrationFunc := range migrationRegistry {
		m := migrationFunc()
		migrations = append(migrations, Migration{
			Version: version,
			Name:    m.Name,
		})
	}

	// Sort by version
	sort.Slice(migrations, func(i, j int) bool {
		return migrations[i].Version < migrations[j].Version
	})

	return migrations
}

func loadMigrationState() *MigrationState {
	state := &MigrationState{
		Applied: []Migration{},
	}

	data, err := os.ReadFile(stateFile)
	if err != nil {
		if os.IsNotExist(err) {
			return state
		}
		fmt.Printf("%sError reading migration state: %v%s\n", colorRed, err, colorReset)
		return state
	}

	err = json.Unmarshal(data, state)
	if err != nil {
		fmt.Printf("%sError parsing migration state: %v%s\n", colorRed, err, colorReset)
		return state
	}

	return state
}

func saveMigrationState(state *MigrationState) error {
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(stateFile, data, 0644)
}

func migrateUp(steps int) {
	fmt.Println(colorCyan + "Running migrations UP" + colorReset)
	fmt.Println("")

	backupState()

	allMigrations := loadMigrations()
	state := loadMigrationState()

	// Find unapplied migrations
	appliedVersions := make(map[int]bool)
	for _, m := range state.Applied {
		appliedVersions[m.Version] = true
	}

	var pending []Migration
	for _, m := range allMigrations {
		if !appliedVersions[m.Version] {
			pending = append(pending, m)
		}
	}

	if len(pending) == 0 {
		fmt.Println(colorGreen + "✓ No pending migrations" + colorReset)
		return
	}

	// Apply migrations
	toApply := pending
	if steps > 0 && steps < len(pending) {
		toApply = pending[:steps]
	}

	for _, migration := range toApply {
		fmt.Printf("%s→ Applying migration %04d: %s%s\n", colorYellow, migration.Version, migration.Name, colorReset)

		// Load and execute migration
		if err := executeMigration(migration, "up"); err != nil {
			fmt.Printf("%s✗ Migration failed: %v%s\n", colorRed, err, colorReset)
			fmt.Println("\nYou may need to manually fix the state")
			os.Exit(1)
		}

		// Mark as applied
		migration.AppliedAt = time.Now()
		state.Applied = append(state.Applied, migration)
		saveMigrationState(state)

		fmt.Printf("%s✓ Migration %04d applied successfully%s\n\n", colorGreen, migration.Version, colorReset)
	}

	fmt.Printf("%s✓ All migrations applied%s\n", colorGreen, colorReset)
}

func migrateDown(steps int) {
	fmt.Println(colorCyan + "Rolling back migrations" + colorReset)
	fmt.Println("")

	backupState()

	state := loadMigrationState()

	if len(state.Applied) == 0 {
		fmt.Println(colorYellow + "No migrations to rollback" + colorReset)
		return
	}

	// Rollback in reverse order
	toRollback := state.Applied
	if steps < len(state.Applied) {
		toRollback = state.Applied[len(state.Applied)-steps:]
	}

	for i := len(toRollback) - 1; i >= 0; i-- {
		migration := toRollback[i]
		fmt.Printf("%s→ Rolling back migration %04d: %s%s\n", colorYellow, migration.Version, migration.Name, colorReset)

		if err := executeMigration(migration, "down"); err != nil {
			fmt.Printf("%s✗ Rollback failed: %v%s\n", colorRed, err, colorReset)
			fmt.Println("\nYou may need to manually fix the state")
			os.Exit(1)
		}

		// Remove from applied
		state.Applied = state.Applied[:len(state.Applied)-1]
		saveMigrationState(state)

		fmt.Printf("%s✓ Migration %04d rolled back%s\n\n", colorGreen, migration.Version, colorReset)
	}

	fmt.Printf("%s✓ Rollback completed%s\n", colorGreen, colorReset)
}

func executeMigration(migration Migration, direction string) error {
	// Load the migration definition from the registry
	migrationFunc, ok := migrationRegistry[migration.Version]
	if !ok {
		return fmt.Errorf("migration %d (%s) not found in registry", migration.Version, migration.Name)
	}

	// Get the full migration definition with commands
	fullMigration := migrationFunc()

	// Select commands based on direction
	var commands []Command
	if direction == "up" {
		commands = fullMigration.Up
	} else if direction == "down" {
		commands = fullMigration.Down
	} else {
		return fmt.Errorf("invalid direction: %s", direction)
	}

	if len(commands) == 0 {
		fmt.Printf("  %sNo operations defined for %s%s\n", colorYellow, direction, colorReset)
		return nil
	}

	// Execute each command
	for i, cmd := range commands {
		fmt.Printf("  [%d/%d] %s%s%s\n", i+1, len(commands), colorBlue, cmd.Description, colorReset)

		if err := executeCommand(cmd); err != nil {
			return fmt.Errorf("command %d failed: %w", i+1, err)
		}

		fmt.Printf("        %s✓ Complete%s\n", colorGreen, colorReset)
	}

	return nil
}

func backupState() {
	timestamp := time.Now().Format("20060102_150405")
	backupFile := fmt.Sprintf("terraform.tfstate.backup_%s", timestamp)

	if _, err := os.Stat("terraform.tfstate"); err == nil {
		input, _ := os.ReadFile("terraform.tfstate")
		os.WriteFile(backupFile, input, 0644)
		fmt.Printf("%s✓ State backed up to: %s%s\n\n", colorGreen, backupFile, colorReset)
	}
}

func showStatus() {
	fmt.Println(colorCyan + "Migration Status" + colorReset)
	fmt.Println("")

	allMigrations := loadMigrations()
	state := loadMigrationState()

	appliedVersions := make(map[int]Migration)
	for _, m := range state.Applied {
		appliedVersions[m.Version] = m
	}

	fmt.Printf("%-8s  %-30s  %-20s  %s\n", "Version", "Name", "Status", "Applied At")
	fmt.Println(strings.Repeat("-", 80))

	for _, m := range allMigrations {
		if applied, ok := appliedVersions[m.Version]; ok {
			fmt.Printf("%s%04d      %-30s  %-20s  %s%s\n",
				colorGreen,
				m.Version,
				truncate(m.Name, 30),
				"✓ Applied",
				applied.AppliedAt.Format("2006-01-02 15:04:05"),
				colorReset)
		} else {
			fmt.Printf("%s%04d      %-30s  %-20s  %s%s\n",
				colorYellow,
				m.Version,
				truncate(m.Name, 30),
				"⧗ Pending",
				"-",
				colorReset)
		}
	}

	fmt.Println("")
	fmt.Printf("Total migrations: %d\n", len(allMigrations))
	fmt.Printf("Applied: %d\n", len(state.Applied))
	fmt.Printf("Pending: %d\n", len(allMigrations)-len(state.Applied))
}

func showVersion() {
	state := loadMigrationState()

	if len(state.Applied) == 0 {
		fmt.Println("Current version: 0 (no migrations applied)")
	} else {
		latest := state.Applied[len(state.Applied)-1]
		fmt.Printf("Current version: %04d (%s)\n", latest.Version, latest.Name)
		fmt.Printf("Applied at: %s\n", latest.AppliedAt.Format("2006-01-02 15:04:05"))
	}
}

func resetMigrations() {
	fmt.Println(colorRed + "WARNING: This will reset all migration tracking!" + colorReset)
	fmt.Println("This does NOT undo migrations, only resets the tracking state.")
	fmt.Println("")
	fmt.Print("Type 'yes' to confirm: ")

	reader := bufio.NewReader(os.Stdin)
	response, _ := reader.ReadString('\n')
	response = strings.TrimSpace(response)

	if response != "yes" {
		fmt.Println(colorYellow + "Reset cancelled" + colorReset)
		return
	}

	state := &MigrationState{Applied: []Migration{}}
	saveMigrationState(state)

	fmt.Println(colorGreen + "✓ Migration state reset" + colorReset)
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max-3] + "..."
}

func runTerraformCommand(args []string) error {
	cmd := exec.Command("terraform", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// executeCommand executes a single migration command
func executeCommand(cmd Command) error {
	switch cmd.Type {
	case string(CommandTypeMove):
		return executeMoveCommand(cmd)
	case string(CommandTypeRemove):
		return executeRemoveCommand(cmd)
	case string(CommandTypeImport):
		return executeImportCommand(cmd)
	default:
		return fmt.Errorf("unknown command type: %s", cmd.Type)
	}
}

// executeMoveCommand executes a terraform state mv command
func executeMoveCommand(cmd Command) error {
	if len(cmd.Args) != 2 {
		return fmt.Errorf("move command requires exactly 2 arguments (source, destination), got %d", len(cmd.Args))
	}

	source := cmd.Args[0]
	destination := cmd.Args[1]

	fmt.Printf("        Running: terraform state mv %s %s\n", source, destination)

	args := []string{"state", "mv", source, destination}
	return runTerraformCommand(args)
}

// executeRemoveCommand executes a terraform state rm command
func executeRemoveCommand(cmd Command) error {
	if len(cmd.Args) != 1 {
		return fmt.Errorf("remove command requires exactly 1 argument (address), got %d", len(cmd.Args))
	}

	address := cmd.Args[0]

	fmt.Printf("        Running: terraform state rm %s\n", address)

	args := []string{"state", "rm", address}
	return runTerraformCommand(args)
}

// executeImportCommand executes a terraform import command
func executeImportCommand(cmd Command) error {
	if len(cmd.Args) != 2 {
		return fmt.Errorf("import command requires exactly 2 arguments (address, id), got %d", len(cmd.Args))
	}

	address := cmd.Args[0]
	id := cmd.Args[1]

	fmt.Printf("        Running: terraform import %s %s\n", address, id)

	args := []string{"import", address, id}
	return runTerraformCommand(args)
}

// registerMigration registers a migration in the global registry
func registerMigration(version int, migrationFunc func() Migration) {
	if _, exists := migrationRegistry[version]; exists {
		panic(fmt.Sprintf("migration version %d is already registered", version))
	}
	migrationRegistry[version] = migrationFunc
}
