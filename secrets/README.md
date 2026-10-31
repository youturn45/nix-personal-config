# GitHub authentication for Nix

[Agenix](https://github.com/ryantm/agenix) decrypts `github-nix.conf.age` at
activation/boot. Its plaintext is a Nix config fragment:

```text
access-tokens = github.com=YOUR_TOKEN
```

`modules/common/secrets/default.nix` includes the runtime secret from the system
`nix.conf`. Only its path enters the Nix store. The file is mode `0400`, owned by
the configured user, and also readable by root for `sudo` rebuilds. This grants
that user and root access to the token. The old `github-token.age` is unused.

## Set up a dedicated token

1. Create a [GitHub personal access token](https://github.com/settings/personal-access-tokens/new).
   For public flake inputs, a fine-grained token with public read access is enough;
   private repositories require explicit repository access and Contents read
   permission. Set an expiration and repeat encryption when rotating the token.
   Broad `repo` or `workflow` scopes are unnecessary for public inputs.
2. Check the recipients in `secrets/secrets.nix`. The initial recipient is the
   public key from this machine's `~/.ssh/Youturn.pub`. Add other machines' public
   keys before encrypting if they use different keys.
3. From the repository root, run:

   ```bash
   python3 scripts/github_nix_token.py encrypt
   git add secrets/github-nix.conf.age
   ```

   Paste the dedicated token at the hidden local prompt. It is passed to `age`
   through stdin and never written to a plaintext temporary file or command
   argument. This requires Python 3, `age`, and `nix-instantiate`, which are already
   available on the current machine. It does not depend on installing agenix first.
   Stage all configuration changes as well: Git flakes omit untracked files.
4. The first rebuild needs authentication **before** agenix is activated:

   ```bash
   python3 scripts/github_nix_token.py run -- just build silk
   ```

   Replace `silk` with the intended host (`ror`, `owl`, or `ozy`). The helper
   decrypts in memory and supplies the setting through `NIX_CONFIG` to that
   command. The existing rebuild recipe preserves it through `sudo -E`.
   Do not wrap commands that dump their environment or Nix configuration.
5. After activation and successful agenix decryption, ordinary `just build` and
   `nix flake update INPUT` invocations read the runtime file automatically.
   Check without displaying the token:

   ```bash
   test -r /run/agenix/github-nix && echo "GitHub auth file is readable"
   ```

   A cached evaluation alone does not prove that GitHub accepted the token.
   An expired/revoked token must be replaced and the configuration rebuilt.

## SSH identities and other hosts

`vars/default.nix` sets `secretsIdentityName = "Youturn"`. Agenix looks for that
key under the configured user's `.ssh` directory on each host. The private key
must be locally present and usable without an interactive passphrase at boot;
a login SSH agent cannot unlock a key for the system service. Prefer a dedicated
unattended age/SSH identity if your existing key needs a passphrase, and update
both the recipients and identity configuration accordingly. Never add a private
key to this repository.

Changing recipients requires **re-encrypting**, not just editing `secrets.nix`:
run the encryption helper again with the token, stage the ciphertext, and rebuild
each host. Each listed public key can independently decrypt the same token.
The helper's `--identity PATH` option (before `run`) can override its default key
for the first rebuild. Host-specific identity paths can override `age.identityPaths`
with `lib.mkForce` in their host configuration.

The agenix CLI is installed by the system configuration. Once installed, edit
the full config fragment with:

```bash
cd secrets
agenix -e github-nix.conf.age -i ~/.ssh/Youturn
```

Keep the `access-tokens = github.com=` prefix; this secret contains a full Nix
config line, not a bare token. Prefer the prompt helper if your editor writes
plaintext swap or backup files.

Before ciphertext exists, the module emits a warning and leaves authentication
unconfigured. It deliberately does not activate the obsolete encrypted secret.

References: [Nix config includes and access tokens](https://nix.dev/manual/nix/2.34/command-ref/conf-file.html),
[agenix identity paths](https://github.com/ryantm/agenix/blob/main/doc/reference.md),
[GitHub token permissions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).
