#!/bin/bash
set -e

# Install dbt with postgres adapter
pip install dbt-core dbt-postgres
sudo apt-get update && sudo apt-get install -y postgresql-client

# Install package deps from integration_tests
cd /workspace/integration_tests
dbt deps

echo "✅ dbt ready." 
echo "Next Run: cd integration_tests && dbt build"