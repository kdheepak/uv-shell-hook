#!/bin/bash
set -euo pipefail

# Test script for bash shell hook functionality
echo "Testing bash shell hook functionality..."

# Store the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Project root: $PROJECT_ROOT"

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Clean up on exit
cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo "Created test directory: $TEST_DIR"

# Create a test project with virtual environment
echo "Creating test project..."
mkdir myproject
cd myproject

# Create virtual environment using real uv
echo "Creating virtual environment..."
command uv venv .venv

# Source the bash hook
echo "Sourcing bash hook..."
eval "$(uv run --project="$PROJECT_ROOT" uv-shell-hook bash)"

# Test 1: Activate virtual environment
echo "Test 1: Activating virtual environment..."
if uv activate; then
    echo "✓ Activation succeeded"
    
    # Check if VIRTUAL_ENV is set
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        echo "✓ VIRTUAL_ENV is set: $VIRTUAL_ENV"
    else
        echo "✗ VIRTUAL_ENV is not set"
        exit 1
    fi
    
    # Check if we can find python in the venv
    if command -v python >/dev/null 2>&1; then
        echo "✓ Python found in PATH"
        PYTHON_PATH=$(which python)
        if [[ "$PYTHON_PATH" == *".venv"* ]]; then
            echo "✓ Python is from virtual environment: $PYTHON_PATH"
        else
            echo "✗ Python is not from virtual environment: $PYTHON_PATH"
            exit 1
        fi
    else
        echo "✗ Python not found"
        exit 1
    fi
else
    echo "✗ Activation failed"
    exit 1
fi

# Test 2: Deactivate virtual environment
echo "Test 2: Deactivating virtual environment..."
if uv deactivate; then
    echo "✓ Deactivation succeeded"
    
    # Check if VIRTUAL_ENV is unset
    if [[ -z "${VIRTUAL_ENV:-}" ]]; then
        echo "✓ VIRTUAL_ENV is unset"
    else
        echo "✗ VIRTUAL_ENV is still set: $VIRTUAL_ENV"
        exit 1
    fi
else
    echo "✗ Deactivation failed"
    exit 1
fi

# Test 3: Try to deactivate when no venv is active
echo "Test 3: Deactivating when no environment is active..."
if uv deactivate 2>/dev/null; then
    echo "✗ Deactivation should have failed but didn't"
    exit 1
else
    echo "✓ Deactivation correctly failed when no environment is active"
fi

# Test 4: Activate non-existent environment
echo "Test 4: Activating non-existent environment..."
if uv activate nonexistent 2>/dev/null; then
    echo "✗ Activation should have failed but didn't"
    exit 1
else
    echo "✓ Activation correctly failed for non-existent environment"
fi

# Test 5: Test that regular uv commands still work
echo "Test 5: Testing regular uv commands..."
if uv --version >/dev/null 2>&1; then
    echo "✓ Regular uv commands work"
else
    echo "✗ Regular uv commands failed"
    exit 1
fi

echo "All tests passed! ✓"
