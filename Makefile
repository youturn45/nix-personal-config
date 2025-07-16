# Makefile for nix-personal-config project
# Integrates with Claude Code hooks for automated linting and testing

.PHONY: lint test lint-nix test-nix lint-go test-go lint-tilt test-tilt lint-python test-python lint-shell check-integration

# Main lint target - called by Claude Code smart-lint.sh
lint:
	@echo "Running project lint with FILE=$(FILE)" >&2
	@if [ -n "$(FILE)" ]; then \
		echo "Linting specific file: $(FILE)" >&2; \
		$(MAKE) lint-file FILE="$(FILE)"; \
	else \
		echo "Linting all files" >&2; \
		$(MAKE) lint-all; \
	fi

# Main test target - called by Claude Code smart-test.sh  
test:
	@echo "Running project tests with FILE=$(FILE)" >&2
	@if [ -n "$(FILE)" ]; then \
		echo "Testing specific file: $(FILE)" >&2; \
		$(MAKE) test-file FILE="$(FILE)"; \
	else \
		echo "Running all tests" >&2; \
		$(MAKE) test-all; \
	fi

# File-specific linting based on file extension
lint-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE variable not set" >&2; \
		exit 1; \
	fi
	@case "$(FILE)" in \
		*.nix) $(MAKE) lint-nix-file FILE="$(FILE)" ;; \
		*.go) $(MAKE) lint-go-file FILE="$(FILE)" ;; \
		*Tiltfile|*.tiltfile) $(MAKE) lint-tilt-file FILE="$(FILE)" ;; \
		*.py) $(MAKE) lint-python-file FILE="$(FILE)" ;; \
		*.sh) $(MAKE) lint-shell-file FILE="$(FILE)" ;; \
		*) echo "No specific linter for $(FILE), running basic checks" >&2; \
		   if [ -f "$(FILE)" ]; then echo "✓ File exists: $(FILE)" >&2; else echo "✗ File not found: $(FILE)" >&2; exit 1; fi ;; \
	esac

# File-specific testing based on file extension
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE variable not set" >&2; \
		exit 1; \
	fi
	@case "$(FILE)" in \
		*.nix) $(MAKE) test-nix-file FILE="$(FILE)" ;; \
		*_test.go|*test.go) $(MAKE) test-go-file FILE="$(FILE)" ;; \
		*.go) $(MAKE) test-go-module FILE="$(FILE)" ;; \
		*Tiltfile|*.tiltfile) $(MAKE) test-tilt-file FILE="$(FILE)" ;; \
		*test*.py|*_test.py) $(MAKE) test-python-file FILE="$(FILE)" ;; \
		*.py) echo "Python file detected, checking for related tests" >&2; $(MAKE) test-python-related FILE="$(FILE)" ;; \
		*) echo "No specific tests for $(FILE)" >&2 ;; \
	esac

# ============================================================================
# NIX LINTING AND TESTING
# ============================================================================

lint-nix-file:
	@echo "🔍 Linting Nix file: $(FILE)" >&2
	@if command -v alejandra >/dev/null 2>&1; then \
		echo "Running alejandra formatter on $(FILE)" >&2; \
		alejandra $(FILE) || exit 1; \
	else \
		echo "alejandra not found, skipping Nix formatting" >&2; \
	fi
	@if command -v nix >/dev/null 2>&1; then \
		echo "Checking Nix syntax for $(FILE)" >&2; \
		nix-instantiate --parse $(FILE) >/dev/null || exit 1; \
	fi

test-nix-file:
	@echo "🧪 Testing Nix file: $(FILE)" >&2
	@if [[ "$(FILE)" == *flake.nix ]]; then \
		echo "Running flake check" >&2; \
		nix flake check --no-build || exit 1; \
	elif [[ "$(FILE)" == hosts/* ]]; then \
		echo "Testing host configuration build" >&2; \
		just build-test || exit 1; \
	else \
		echo "Running basic Nix evaluation test" >&2; \
		nix-instantiate --eval $(FILE) >/dev/null || exit 1; \
	fi

lint-nix:
	@echo "🔍 Formatting all Nix files" >&2
	@if command -v alejandra >/dev/null 2>&1; then \
		alejandra . || exit 1; \
	fi
	@echo "Running flake check" >&2
	@nix flake check --no-build || exit 1

test-nix:
	@echo "🧪 Testing Nix configuration" >&2
	@just build-test || exit 1

# ============================================================================
# GO LINTING AND TESTING (for test fixtures)
# ============================================================================

lint-go-file:
	@echo "🔍 Linting Go file: $(FILE)" >&2
	@go_mod_dir=$$(dirname "$(FILE)"); \
	while [[ "$$go_mod_dir" != "." && "$$go_mod_dir" != "/" ]]; do \
		if [[ -f "$$go_mod_dir/go.mod" ]]; then \
			echo "Found Go module in $$go_mod_dir" >&2; \
			cd "$$go_mod_dir" && \
			gofmt -w "$(FILE)" && \
			if command -v golangci-lint >/dev/null 2>&1; then \
				golangci-lint run "$(FILE)" || exit 1; \
			else \
				go vet "$(FILE)" || exit 1; \
			fi; \
			exit 0; \
		fi; \
		go_mod_dir=$$(dirname "$$go_mod_dir"); \
	done; \
	echo "No go.mod found for $(FILE), running basic formatting" >&2; \
	gofmt -w "$(FILE)"

test-go-file:
	@echo "🧪 Testing Go file: $(FILE)" >&2
	@go_mod_dir=$$(dirname "$(FILE)"); \
	while [[ "$$go_mod_dir" != "." && "$$go_mod_dir" != "/" ]]; do \
		if [[ -f "$$go_mod_dir/go.mod" ]]; then \
			echo "Running tests in Go module: $$go_mod_dir" >&2; \
			cd "$$go_mod_dir" && go test -v ./... || exit 1; \
			exit 0; \
		fi; \
		go_mod_dir=$$(dirname "$$go_mod_dir"); \
	done; \
	echo "No go.mod found for $(FILE)" >&2

test-go-module:
	@echo "🧪 Testing Go module containing: $(FILE)" >&2
	@go_mod_dir=$$(dirname "$(FILE)"); \
	while [[ "$$go_mod_dir" != "." && "$$go_mod_dir" != "/" ]]; do \
		if [[ -f "$$go_mod_dir/go.mod" ]]; then \
			echo "Running tests for Go module: $$go_mod_dir" >&2; \
			cd "$$go_mod_dir" && go test -v ./... || exit 1; \
			exit 0; \
		fi; \
		go_mod_dir=$$(dirname "$$go_mod_dir"); \
	done; \
	echo "No go.mod found for $(FILE)" >&2

# ============================================================================
# TILT LINTING AND TESTING (for test fixtures)
# ============================================================================

lint-tilt-file:
	@echo "🔍 Linting Tilt file: $(FILE)" >&2
	@if command -v starlark >/dev/null 2>&1; then \
		echo "Running starlark syntax check on $(FILE)" >&2; \
		starlark --check "$(FILE)" || exit 1; \
	else \
		echo "starlark not found, skipping syntax check" >&2; \
	fi
	@if command -v flake8 >/dev/null 2>&1; then \
		echo "Running flake8 on $(FILE)" >&2; \
		flake8 "$(FILE)" || exit 1; \
	fi

test-tilt-file:
	@echo "🧪 Testing Tilt file: $(FILE)" >&2
	@tilt_dir=$$(dirname "$(FILE)"); \
	if [[ -f "$$tilt_dir/Tiltfile_test.py" ]]; then \
		echo "Running Python tests for $(FILE)" >&2; \
		cd "$$tilt_dir" && python -m pytest Tiltfile_test.py -v || exit 1; \
	elif [[ -f "$$tilt_dir/test_tiltfile.py" ]]; then \
		echo "Running Python tests for $(FILE)" >&2; \
		cd "$$tilt_dir" && python -m pytest test_tiltfile.py -v || exit 1; \
	else \
		echo "No tests found for $(FILE)" >&2; \
	fi

# ============================================================================
# PYTHON LINTING AND TESTING (for hook scripts)
# ============================================================================

lint-python-file:
	@echo "🔍 Linting Python file: $(FILE)" >&2
	@if command -v black >/dev/null 2>&1; then \
		black "$(FILE)" || exit 1; \
	fi
	@if command -v ruff >/dev/null 2>&1; then \
		ruff check --fix "$(FILE)" || exit 1; \
	elif command -v flake8 >/dev/null 2>&1; then \
		flake8 "$(FILE)" || exit 1; \
	fi

test-python-file:
	@echo "🧪 Testing Python file: $(FILE)" >&2
	@if [[ "$(FILE)" == *test*.py || "$(FILE)" == *_test.py ]]; then \
		pytest -xvs "$(FILE)" || exit 1; \
	else \
		echo "Not a test file: $(FILE)" >&2; \
	fi

test-python-related:
	@echo "🧪 Looking for tests related to: $(FILE)" >&2
	@base_name=$$(basename "$(FILE)" .py); \
	dir_name=$$(dirname "$(FILE)"); \
	if [[ -f "$$dir_name/test_$$base_name.py" ]]; then \
		pytest -xvs "$$dir_name/test_$$base_name.py" || exit 1; \
	elif [[ -f "$$dir_name/$${base_name}_test.py" ]]; then \
		pytest -xvs "$$dir_name/$${base_name}_test.py" || exit 1; \
	else \
		echo "No tests found for $(FILE)" >&2; \
	fi

# ============================================================================
# SHELL SCRIPT LINTING
# ============================================================================

lint-shell-file:
	@echo "🔍 Linting shell file: $(FILE)" >&2
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck "$(FILE)" || exit 1; \
	else \
		echo "shellcheck not found, skipping shell linting" >&2; \
	fi
	@bash -n "$(FILE)" || exit 1

# ============================================================================
# PROJECT-WIDE TARGETS
# ============================================================================

lint-all:
	@echo "🔍 Running comprehensive project linting" >&2
	@$(MAKE) lint-nix
	@echo "Linting shell scripts" >&2
	@find . -name "*.sh" -not -path "./.*" -exec $(MAKE) lint-shell-file FILE={} \;
	@echo "Linting Python scripts" >&2
	@find . -name "*.py" -not -path "./.*" -exec $(MAKE) lint-python-file FILE={} \;

test-all:
	@echo "🧪 Running comprehensive project tests" >&2
	@$(MAKE) test-nix
	@echo "Running hook script tests" >&2
	@if [[ -d "home/base/claude-code/hooks/spec" ]]; then \
		cd home/base/claude-code/hooks && \
		find spec -name "*_spec.sh" -exec bash {} \; || exit 1; \
	fi

# ============================================================================
# UTILITIES
# ============================================================================

check-integration:
	@echo "✓ Makefile detected by Claude Code hooks" >&2
	@echo "  - 'make lint' target: available" >&2
	@echo "  - 'make test' target: available" >&2
	@echo "" >&2
	@echo "File type support:" >&2
	@echo "  - *.nix: Nix formatting with alejandra, syntax checking" >&2
	@echo "  - *.go: Go formatting with gofmt, linting with golangci-lint" >&2
	@echo "  - *Tiltfile, *.tiltfile: Starlark syntax checking, flake8" >&2
	@echo "  - *.py: Python formatting with black, linting with ruff/flake8" >&2
	@echo "  - *.sh: Shell linting with shellcheck" >&2
	@echo "" >&2
	@echo "Test with:" >&2
	@echo "  make lint FILE=flake.nix" >&2
	@echo "  make test FILE=hosts/darwin/rorschach.nix" >&2
	@echo "  make lint FILE=home/base/claude-code/hooks/spec/lint-go/fixtures/should-pass-clean-code/main.go" >&2