# TODO list of items

## Existing Items
- [ ] figure out how to add sudo batt activate into script

## Nix Configuration Improvements (Analysis Completed)

### High Priority (Fix Immediately)
- [ ] **CRITICAL: Remove duplicate Neovim configurations**
  - Files: `home/base/core/editors/neovim/` and `home/base/_tui/editors/neovim/`
  - Action: Consolidate to single shared module in `home/base/_shared/neovim/`
  
- [ ] **Fix hardcoded paths in Neovim configurations**
  - Line 20 in both Neovim files: `configPath` uses wrong path (`tui` vs `_tui`)
  - Action: Use relative paths or derive from repository root
  
- [ ] **Clean up copied helper functions**
  - File: `my-lib/default.nix` lines 9-125
  - Action: Remove unused helper functions (martin, vader, phasma, etc.), keep only `collectModulesRecursively`
  
- [ ] **Centralize timezone configuration**
  - Currently set in 3 different places
  - Action: Move to `vars/default.nix` and reference from modules
  
- [ ] **Address outstanding TODO items in codebase**
  - `home/default.nix:5` - "TODO correctly import neovim"
  - `apps.nix:66,84,94,102` - Multiple Homebrew TODOs
  - Action: Fix or remove outdated TODOs

### Medium Priority (Next Sprint)
- [ ] **Add input validation to vars/default.nix**
  - Add assertions for hostname, username, system compatibility
  
- [ ] **Optimize package imports in flake.nix**
  - Lines 75-91: Three separate identical package imports
  - Action: Create `mkPkgs` helper function
  
- [ ] **Consolidate module organization**
  - Decide on single authoritative location for editors
  - Clarify underscore naming convention
  
- [ ] **Fix flake input redundancy**
  - Lines 15-23 in flake.nix: `nixpkgs` and `nixpkgs-unstable` point to same source
  - Action: Use different channels or remove duplicate
  
- [ ] **Add proper error handling**
  - Add validation throughout configurations
  - Improve error messages for common failures

### Low Priority (Technical Debt)
- [ ] **Security improvements**
  - Add timeout controls to TouchID sudo configuration
  - Move sensitive data (email) from version control
  
- [ ] **Performance optimizations**
  - Optimize tree-sitter grammar loading (specify only needed grammars)
  - Review and optimize large package imports
  
- [ ] **Create host-specific override mechanism**
  - Allow per-host customization without duplicating entire configs
  
- [ ] **Standardize naming conventions**
  - Clarify underscore prefix meaning and usage
  - Ensure consistent patterns across all modules
  
- [ ] **Add documentation**
  - Document module architecture and design decisions
  - Add usage examples for custom helper functions
  
- [ ] **Set up automated validation**
  - CI/CD for flake.lock currency
  - Automated security updates for dependencies

### Architecture Issues Identified
- **Code Duplication**: Exact duplicate Neovim configs (75 lines each)
- **Inconsistent Patterns**: Mixed import styles and helper usage  
- **Missing Validation**: No error checking for critical variables
- **Outdated Patterns**: Deprecated Nix patterns and URL imports
- **Performance Issues**: Inefficient package loading and parsing
- **Security Gaps**: Unsafe sudo config, hardcoded personal info
- **Documentation Debt**: Missing module docs and usage examples
