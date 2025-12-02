# Secrets Management with Agenix

This directory contains encrypted secrets managed by [agenix](https://github.com/ryantm/agenix).

## Overview

Secrets are encrypted using age encryption with SSH keys. Only authorized SSH keys (defined in `../secrets.nix`) can decrypt these secrets.

## Current Secrets

- `github-token.age` - GitHub Personal Access Token
- `ssh-key-rorschach.age` - SSH private key for Rorschach host

## Setup Instructions

### 1. Generate an SSH Key for Secrets Management

If you don't already have an SSH key, generate one:

```bash
# On your Mac (Rorschach)
ssh-keygen -t ed25519 -C "agenix-key-$(hostname)"

# Accept the default location (~/.ssh/id_ed25519)
# Set a strong passphrase
```

### 2. Add Your Public Key to secrets.nix

Copy your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Then update the `youturn-rorschach` variable in `/secrets.nix` with your actual public key.

If you have multiple machines, add their keys too:

```nix
# In secrets.nix
youturn-nightowl = "ssh-ed25519 AAAA... youturn@NightOwl";
youturn-silkspectre = "ssh-ed25519 AAAA... youturn@SilkSpectre";

allKeys = [
  youturn-rorschach
  youturn-nightowl
  youturn-silkspectre
];
```

### 3. Create and Encrypt the GitHub Token

```bash
# Navigate to repository root
cd ~/nix-personal-config

# Create a GitHub token at: https://github.com/settings/tokens
# Select appropriate scopes (repo, workflow, etc.)

# Create a temporary file with your token
echo "ghp_YourGitHubTokenHere" > /tmp/github-token.txt

# Encrypt the token using agenix
# The -i flag specifies your SSH private key
agenix -e secrets/github-token.age -i ~/.ssh/id_ed25519

# This will open your $EDITOR (vim/nano/etc)
# Paste your token, save, and exit
# Alternatively, you can pipe it directly:
cat /tmp/github-token.txt | agenix -e secrets/github-token.age -i ~/.ssh/id_ed25519

# Securely delete the temporary file
rm -P /tmp/github-token.txt  # macOS
# or
shred -u /tmp/github-token.txt  # Linux
```

### 4. Build and Apply Your Configuration

```bash
# Test the build first
just build-test

# If successful, apply the configuration
just safe-build

# Or use the quick alias
just ror
```

### 5. Verify the Secret is Available

After building, the decrypted secret will be available at:

```bash
# Check if the file exists
ls -la ~/.config/github/token

# Read the token (be careful not to expose it!)
cat ~/.config/github/token

# Or use the helper command
github-token
```

## Using the GitHub Token

### In Scripts

```bash
#!/usr/bin/env bash

# Read the token from the file
GITHUB_TOKEN=$(cat ~/.config/github/token)

# Use it with GitHub API
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user/repos
```

### With Environment Variable

The system sets `GITHUB_TOKEN_FILE` environment variable automatically:

```bash
# In your shell
GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
```

### With GitHub CLI (gh)

```bash
# Login using the token
cat ~/.config/github/token | gh auth login --with-token

# Or set it as an environment variable
export GITHUB_TOKEN=$(cat ~/.config/github/token)
gh repo list
```

### With Git

```bash
# For HTTPS clone/push, use the token as password
git clone https://$(cat ~/.config/github/token)@github.com/user/repo.git

# Or configure git credential helper
git config --global credential.helper store
echo "https://$(cat ~/.config/github/token)@github.com" >> ~/.git-credentials
```

## Managing Secrets

### Adding a New Secret

1. Add the secret definition to `secrets.nix`:

```nix
{
  "secrets/my-new-secret.age".publicKeys = allKeys;
}
```

2. Create and encrypt the secret:

```bash
agenix -e secrets/my-new-secret.age -i ~/.ssh/id_ed25519
```

3. Add the secret to `modules/darwin/secrets.nix`:

```nix
age.secrets.my-new-secret = {
  file = ../../secrets/my-new-secret.age;
  path = "/Users/${myvars.username}/.config/my-app/secret";
  owner = myvars.username;
  group = "staff";
  mode = "0400";
};
```

4. Rebuild your system:

```bash
just safe-build
```

### Editing an Existing Secret

```bash
# Edit the GitHub token
agenix -e secrets/github-token.age -i ~/.ssh/id_ed25519

# Save and rebuild
just safe-build
```

### Re-encrypting Secrets (After Adding New Keys)

When you add a new authorized key to `secrets.nix`, you need to re-encrypt all secrets:

```bash
# Re-encrypt all secrets
cd secrets
for file in *.age; do
  agenix -r -e "$file" -i ~/.ssh/id_ed25519
done
```

### Listing Available Secrets

```bash
# See all encrypted secrets
ls -la secrets/*.age

# See all configured secrets in the system
darwin-rebuild build --flake .#Rorschach --show-trace 2>&1 | grep "age.secrets"
```

## Security Best Practices

1. **Never commit unencrypted secrets** - Only `.age` files should be in git
2. **Use strong SSH key passphrases** - Your secrets are only as secure as your SSH key
3. **Rotate tokens regularly** - Update GitHub tokens periodically
4. **Limit token scopes** - Only grant necessary permissions to GitHub tokens
5. **Use different tokens for different purposes** - Don't reuse tokens across services
6. **Backup your SSH keys** - Store encrypted backups of your SSH private keys
7. **Review authorized keys** - Regularly audit `secrets.nix` for unauthorized keys
8. **Use read-only permissions** - Set mode to `0400` for sensitive secrets

## Troubleshooting

### "Permission denied" when accessing secret

```bash
# Check file permissions
ls -la ~/.config/github/token

# Should be owned by you with mode 0400
# If not, rebuild:
just safe-build
```

### "Cannot decrypt" error

```bash
# Verify your public key is in secrets.nix
cat ~/.ssh/id_ed25519.pub
grep "$(cat ~/.ssh/id_ed25519.pub)" secrets.nix

# If not found, add it and re-encrypt
agenix -r -e secrets/github-token.age -i ~/.ssh/id_ed25519
```

### Secret file not found after rebuild

```bash
# Check the secret is defined in modules/darwin/secrets.nix
grep "github-token" modules/darwin/secrets.nix

# Verify the .age file exists
ls -la secrets/github-token.age

# Check build logs for errors
just build-test 2>&1 | grep -i age
```

### Need to use a different SSH key

```bash
# Specify the key explicitly with -i flag
agenix -e secrets/github-token.age -i ~/.ssh/other_key_ed25519
```

## Additional Resources

- [Agenix Documentation](https://github.com/ryantm/agenix)
- [Age Encryption Specification](https://age-encryption.org/)
- [GitHub Token Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [Nix Secrets Management Comparison](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
