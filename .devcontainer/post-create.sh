#!/bin/bash
set -e

# Install dbt with postgres adapter
pip install dbt-core dbt-postgres

# Install package deps from integration_tests
cd /workspace/integration_tests
dbt deps

echo "✅ dbt ready." 
echo "Next Run: cd integration_tests && dbt build"