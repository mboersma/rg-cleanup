#!/bin/bash

set -euo pipefail

# Parse out --role-assignments flag
role_assignments_flag=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --role-assignments) role_assignments_flag=true ;;
    *) args+=("$1") ;;  # Store other arguments in an array
  esac
  shift
done

# Call resource group cleanup binary with its command-line arguments
rg-cleanup "${args[@]}"

# Exit if not cleaning up unattached role assignments
if [ "$role_assignments_flag" != true ]; then
  exit 0
fi

# Clean up unattached role assignments
az login --identity
az account set --subscription "${SUBSCRIPTION_ID}"

QUERY=".[] | select(.scope == \"/subscriptions/${SUBSCRIPTION_ID}\" and .principalName==\"\") .id"
for R_ID in $(az role assignment list --all --include-inherited -o json | jq -r "${QUERY}"); do
  echo "Deleting unattached role assignment: $R_ID"
  az role assignment delete --ids $R_ID
done
