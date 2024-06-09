.PHONY: check-formatting credo compile test nix-build nix-check

check-formatting:
	mix format --check-formatted

credo:
	mix credo --format sarif

compile:
	mix compile --warnings-as-errors

test:
	mix test --warnings-as-errors

nix-build:
	nix build

nix-check:
	nix flake check
