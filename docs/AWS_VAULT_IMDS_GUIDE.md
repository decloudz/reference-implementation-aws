# AWS Vault Integration Guide

This guide explains how to use `aws-vault` with this reference implementation for secure AWS credential management. Based on the [official aws-vault documentation](https://github.com/99designs/aws-vault), we provide multiple integration approaches optimized for different use cases.

## Overview

`aws-vault` is a tool to securely store and access AWS credentials in development environments. This implementation provides two approaches:

1. **Environment Variable Mode** - Simple credential injection (best for CI/CD)
2. **ECS Credential Server Mode** - Auto-refreshing credential server (best for development)
3. **EC2 Metadata Server Mode** - IMDS simulation (deprecated due to compatibility issues)

## Recommended Approach: Environment Variable Mode

### Why Environment Variables?

The environment variable approach is more reliable because:
- ✅ Works consistently across all operating systems
- ✅ No complex network configuration required
- ✅ Better security (no local HTTP server)
- ✅ Integrates seamlessly with kubectl exec provider
- ✅ No sudo requirements

### Installation & Setup

1. **Install aws-vault**:
   ```bash
   # macOS
   brew install aws-vault
   
   # Linux
   curl -Ls https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-amd64 -o aws-vault
   sudo mv aws-vault /usr/local/bin/
   chmod +x /usr/local/bin/aws-vault
   ```

2. **Configure your AWS profile**:
   ```bash
   aws-vault add my-profile
   # Enter your AWS Access Key ID and Secret Access Key
   ```

3. **Test the profile**:
   ```bash
   aws-vault exec my-profile -- aws sts get-caller-identity
   ```

### Usage

Use the environment variable installation script:

```bash
AWS_VAULT_PROFILE=my-profile ./scripts/install-with-vault-env.sh
```

This approach:
- Uses `aws-vault exec` to inject credentials into the installation process
- Configures the kubeconfig to use `aws-vault` for EKS token generation
- No local IMDS server required

### How It Works

1. **Installation**: The script uses `aws-vault exec` to run all AWS commands with injected credentials
2. **Kubeconfig**: The generated kubeconfig uses this exec provider:
   ```yaml
   execProviderConfig:
     command: "aws-vault"
     args: ["exec", "my-profile", "--", "aws", "eks", "get-token", "--cluster-name", "cluster-name"]
   ```
3. **Runtime**: When kubectl needs credentials, it automatically calls aws-vault to get fresh tokens

## Available Installation Scripts

We provide three different scripts for different use cases:

### 1. Environment Variable Mode (`install-with-vault-env.sh`)
```bash
AWS_VAULT_PROFILE=my-profile ./scripts/install-with-vault-env.sh
```
**Best for**: CI/CD pipelines, simple setups, maximum compatibility
- ✅ Simplest approach
- ✅ Works everywhere
- ❌ No automatic credential refresh

### 2. ECS Credential Server Mode (`install-with-vault-ecs.sh`) 
```bash
AWS_VAULT_PROFILE=my-profile ./scripts/install-with-vault-ecs.sh
```
**Best for**: Development environments, long-running processes
- ✅ Automatic credential refresh
- ✅ Cross-platform compatible
- ✅ Standard AWS SDK pattern

### 3. Original Installation (`install.sh`)
```bash
AWS_PROFILE=my-profile ./scripts/install.sh
```
**Best for**: Traditional AWS profiles, static credentials
- ✅ Simple and familiar
- ❌ Less secure (long-lived credentials)

## Alternative: ECS Credential Server Mode

The aws-vault `--server` flag provides an ECS-compatible credential server that's more reliable than EC2 metadata simulation.

### How ECS Credential Server Works

From the [official aws-vault documentation](https://github.com/99designs/aws-vault), when you use `--server`:

```bash
$ aws-vault exec --server jonsmith -- env | grep AWS
AWS_VAULT=jonsmith
AWS_DEFAULT_REGION=us-east-1
AWS_REGION=us-east-1
AWS_CONTAINER_CREDENTIALS_FULL_URI=%%%
AWS_CONTAINER_AUTHORIZATION_TOKEN=%%%
```

### Benefits of ECS Credential Server

- ✅ **No sudo required** - Uses random high port (not port 80)
- ✅ **Cross-platform** - Works reliably on macOS, Linux, Windows
- ✅ **Automatic refresh** - AWS SDKs automatically refresh credentials
- ✅ **Standard pattern** - Uses AWS_CONTAINER_CREDENTIALS_FULL_URI
- ✅ **No network configuration** - No iptables/pfctl rules needed

### Usage with ECS Credential Server

Use the ECS credential server installation script:

```bash
AWS_VAULT_PROFILE=my-profile ./scripts/install-with-vault-ecs.sh
```

This approach:
- Starts aws-vault with `--server` flag (ECS credential server)
- Configures kubeconfig to use the ECS credential provider
- Passes credentials via `AWS_CONTAINER_CREDENTIALS_FULL_URI`

### Testing ECS Credential Server

```bash
# Start ECS credential server
aws-vault exec --server my-profile -- env | grep AWS

# Should show:
# AWS_CONTAINER_CREDENTIALS_FULL_URI=http://127.0.0.1:<random-port>
# AWS_CONTAINER_AUTHORIZATION_TOKEN=<token>

# Test AWS CLI works
aws-vault exec --server my-profile -- aws sts get-caller-identity
```

## Benefits of aws-vault

### Security
- 🔐 **Encrypted Storage**: Credentials stored securely in OS keychain/keyring
- 🔄 **Temporary Credentials**: Automatic STS token rotation
- 🚫 **No Plain Text**: Never stores long-term credentials in files
- 👤 **MFA Support**: Works with multi-factor authentication

### Developer Experience
- 🎯 **Profile Switching**: Easy switching between AWS accounts/roles
- 🔧 **Tool Integration**: Works with all AWS-compatible tools
- 📱 **Session Management**: Handles STS session lifecycle
- 🌐 **Cross-Platform**: Works on macOS, Linux, and Windows

### Operational Benefits
- ⚡ **No IMDS Complexity**: No need for local metadata servers
- 🔗 **Native Integration**: Direct integration with kubectl exec provider
- 📋 **Audit Trail**: Better logging and credential usage tracking
- 🚀 **Performance**: No additional network hops or proxy overhead

## Comparison with Other Approaches

| Approach | Security | Complexity | Compatibility | Auto Refresh | Recommended |
|----------|----------|------------|---------------|--------------|-------------|
| **aws-vault (env vars)** | ✅ High | ✅ Low | ✅ All OS | ❌ No | ✅ **Best for CI/CD** |
| **aws-vault (ECS server)** | ✅ High | ✅ Medium | ✅ All OS | ✅ Yes | ✅ **Best for dev** |
| aws-vault (EC2 metadata) | ✅ High | ❌ High | ⚠️ Linux only | ✅ Yes | ❌ Deprecated |
| Static credentials | ❌ Low | ✅ Low | ✅ All OS | ❌ No | ❌ No |
| AWS SSO | ✅ High | ✅ Medium | ✅ All OS | ✅ Yes | ✅ Alternative |

## Migration from Static Credentials

If you're currently using static credentials:

1. **Back up your current config**: 
   ```bash
   cp ~/.aws/credentials ~/.aws/credentials.backup
   ```

2. **Add profiles to aws-vault**:
   ```bash
   aws-vault add production
   aws-vault add development
   ```

3. **Test the migration**:
   ```bash
   aws-vault exec production -- aws sts get-caller-identity
   ```

4. **Update your workflows**:
   ```bash
   # Old way
   AWS_PROFILE=production ./scripts/install.sh
   
   # New way
   AWS_VAULT_PROFILE=production ./scripts/install-with-vault-env.sh
   ```

## Troubleshooting

### Common Issues

**"Profile not found"**:
```bash
aws-vault list  # Check available profiles
aws-vault add my-profile  # Add missing profile
```

**"Command not found: aws-vault"**:
```bash
# Reinstall aws-vault
brew install aws-vault  # macOS
```

**"Failed to get credentials"**:
```bash
# Check profile configuration
aws-vault exec my-profile -- aws sts get-caller-identity
```

**"MFA token required"**:
```bash
# aws-vault will prompt for MFA token automatically
aws-vault exec my-profile -- aws sts get-caller-identity
```

### Debug Mode

For detailed troubleshooting:
```bash
aws-vault --debug exec my-profile -- aws sts get-caller-identity
```

## Security Best Practices

1. **Use MFA**: Configure MFA for your AWS accounts
2. **Short Sessions**: Use shorter session durations for sensitive operations
3. **Profile Separation**: Use different profiles for different environments
4. **Regular Rotation**: Rotate access keys regularly
5. **Audit Access**: Monitor AWS CloudTrail for credential usage

## Further Reading

- [aws-vault GitHub Repository](https://github.com/99designs/aws-vault)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Kubernetes Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/) 