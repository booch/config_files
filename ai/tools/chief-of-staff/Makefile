.PHONY: install specs lint format
install: ; bun install
specs: ; bun test
lint: ; bunx biome check . && bunx tsc --noEmit
format: ; bunx biome check --write .
