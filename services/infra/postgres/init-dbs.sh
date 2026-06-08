#!/bin/bash
set -e

echo "Creating databases..."
psql -U postgres -c "CREATE DATABASE assignment_db;"
psql -U postgres -c "CREATE DATABASE submission_db;"
psql -U postgres -c "CREATE DATABASE grading_db;"
psql -U postgres -c "CREATE DATABASE result_db;"
psql -U postgres -c "CREATE DATABASE notification_db;"
psql -U postgres -c "CREATE DATABASE keycloak_db;"
echo "All databases created successfully!"
