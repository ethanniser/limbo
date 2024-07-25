MINIMUM_RUST_VERSION := 1.73.0
CURRENT_RUST_VERSION := $(shell rustc -V | sed -E 's/rustc ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
RUSTUP := $(shell command -v rustup 2> /dev/null)

# Executable used to execute the compatibility tests.
SQLITE_EXEC ?= ./target/debug/limbo

# Static library to use for SQLite C API compatibility tests.
SQLITE_LIB ?= ./target/debug/liblimbo_sqlite3.a

# Reference Implementation to Check Against
ACTUAL_SQLITE_EXEC ?= sqlite3

all: check-rust-version check-wasm-target limbo limbo-wasm
.PHONY: all

check-rust-version:
	@echo "Checking Rust version..."
	@if [ "$(shell printf '%s\n' "$(MINIMUM_RUST_VERSION)" "$(CURRENT_RUST_VERSION)" | sort -V | head -n1)" = "$(CURRENT_RUST_VERSION)" ]; then \
		echo "Rust version greater than $(MINIMUM_RUST_VERSION) is required. Current version is $(CURRENT_RUST_VERSION)."; \
		if [ -n "$(RUSTUP)" ]; then \
			echo "Updating Rust..."; \
			rustup update stable; \
		else \
			echo "Please update Rust manually to a version greater than $(MINIMUM_RUST_VERSION)."; \
			exit 1; \
		fi; \
	else \
		echo "Rust version $(CURRENT_RUST_VERSION) is acceptable."; \
	fi
.PHONY: check-rust-version

check-wasm-target:
	@echo "Checking wasm32-wasi target..."
	@if ! rustup target list | grep -q "wasm32-wasi (installed)"; then \
		echo "Installing wasm32-wasi target..."; \
		rustup target add wasm32-wasi; \
	fi
.PHONY: check-wasm-target

limbo:
	cargo build
.PHONY: limbo

limbo-wasm:
	rustup target add wasm32-wasi
	cargo build --package limbo-wasm --target wasm32-wasi
.PHONY: limbo-wasm

test: limbo test-reference test-compat test-sqlite3
.PHONY: test

test-compat:
	SQLITE_EXEC=$(SQLITE_EXEC) ./testing/all.test
.PHONY: test-compat

test-sqlite3:
	LIBS=../../$(SQLITE_LIB) make -C sqlite3/tests test
.PHONY: test-sqlite3

test-reference:
	SQLITE_EXEC=$(ACTUAL_SQLITE_EXEC) ./testing/all.test
.PHONY: test-reference
