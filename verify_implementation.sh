#!/bin/bash

# Manual code verification script for offline animal creation feature

echo "=== Offline Animal Creation Feature Verification ==="
echo

echo "1. Checking if all required files exist..."
FILES=(
    "lib/models/pending_sync_models.dart"
    "lib/screens/pending_sync_screen.dart"
    "lib/screens/create_animal_screen.dart"
    "lib/screens/home_screen.dart"
    "lib/services/database_service.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo
echo "2. Checking database service methods..."

# Check if new methods exist in database service
METHODS=(
    "savePendingAnimalOffline"
    "getPendingAnimalsOffline" 
    "markAnimalAsSynced"
    "getAllPendingRecords"
)

for method in "${METHODS[@]}"; do
    if grep -q "$method" lib/services/database_service.dart; then
        echo "✓ DatabaseService.$method() found"
    else
        echo "✗ DatabaseService.$method() missing"
    fi
done

echo
echo "3. Checking database schema updates..."

# Check if database version was updated
if grep -q "version: 8" lib/services/database_service.dart; then
    echo "✓ Database version updated to 8"
else
    echo "✗ Database version not updated"
fi

# Check if new columns are added in upgrade
COLUMNS=(
    "synced INTEGER DEFAULT 1"
    "is_pending INTEGER DEFAULT 0"
    "pending_operation TEXT"
    "estado_id INTEGER"
    "etapa_id INTEGER"
)

for column in "${COLUMNS[@]}"; do
    if grep -q "$column" lib/services/database_service.dart; then
        echo "✓ Column '$column' added"
    else
        echo "✗ Column '$column' missing"
    fi
done

echo
echo "4. Checking UI navigation updates..."

# Check if pending sync screen is imported and used in home screen
if grep -q "pending_sync_screen.dart" lib/screens/home_screen.dart; then
    echo "✓ PendingSyncScreen imported in HomeScreen"
else
    echo "✗ PendingSyncScreen not imported in HomeScreen"
fi

if grep -q "PendingSyncScreen" lib/screens/home_screen.dart; then
    echo "✓ PendingSyncScreen used in HomeScreen"
else
    echo "✗ PendingSyncScreen not used in HomeScreen"
fi

echo
echo "5. Checking offline functionality in create animal screen..."

# Check if offline logic is implemented
if grep -q "if (_isOffline)" lib/screens/create_animal_screen.dart; then
    echo "✓ Offline condition check found"
else
    echo "✗ Offline condition check missing"
fi

if grep -q "savePendingAnimalOffline" lib/screens/create_animal_screen.dart; then
    echo "✓ Offline animal saving implemented"
else
    echo "✗ Offline animal saving missing"
fi

echo
echo "6. Checking test files..."

TEST_FILES=(
    "test/pending_animal_offline_test.dart"
    "test/database_migration_test.dart"
    "test/offline_animal_integration_test.dart"
)

for file in "${TEST_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo
echo "=== Verification Complete ==="