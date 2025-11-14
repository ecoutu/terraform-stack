#!/bin/bash
#
# Wrapper script to run Terraform state migrations
# This allows running migrations from the project root directory
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

# Check if migrate binary exists
if [ ! -f "$MIGRATIONS_DIR/migrate" ]; then
    echo "Migration tool not built. Building now..."
    cd "$MIGRATIONS_DIR" && go build -buildvcs=false -o migrate . || {
        echo "Failed to build migration tool"
        exit 1
    }
    cd "$SCRIPT_DIR"
    echo "✓ Migration tool built successfully"
    echo ""
fi

# Run the migration tool
"$MIGRATIONS_DIR/migrate" "$@"
