# Github Action Workflows

[Github Actions](https://docs.github.com/en/actions) to automate, customize, and execute your software development workflows coupled with the repository.

## Local Actions

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits

Store the identical Secrets in Github Organization/Repository to local workstation

```
cat <<EOF > ~/creds/azure.secrets
# Terraform.io Token
TF_API_TOKEN_AZURE_WORKSPACE=...

# Github PAT
GITHUB_TOKEN=...

# Azure
AZURE_TENANT_ID=...
AZURE_SUBSCRIPTION_ID=...
AZURE_CLIENT_ID=...
AZURE_CLIENT_SECRET=...
EOF
```

### Manual Dispatch Testing

```
# Try the Terraform Read job first
act -j terraform-read \
    -e .github/local.json \
    --secret-file ~/creds/azure.secrets \
    --remote-name $(git remote show)

# Use the Terraform Write job to apply/destroy the infra configuration
act -j terraform-write \
    -e .github/local.json \
    --secret-file ~/creds/azure.secrets \
    --remote-name $(git remote show)
```

### Integration Testing

```
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
    -e .github/local.json \
    --secret-file ~/development/terraform/creds/azure.secrets \
    --remote-name $(git remote show) \ 
    --artifact-server-path /tmp/artifacts
```

### Unit Testing

```
act -j terraform-unit-tests \
    -e .github/local.json \
    --remote-name sim-parables
```