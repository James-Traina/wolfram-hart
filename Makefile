.PHONY: test lint check

test: ## Run all 100 tests (requires wolframscript)
	bash tests/run-tests.sh

lint: ## Syntax-check all shell scripts
	@for f in skills/wolfram-hart/scripts/*.sh tests/run-tests.sh tests/helpers.sh tests/batch-*.sh; do \
		bash -n "$$f" && printf '  ok  %s\n' "$$f" || exit 1; \
	done
	@echo "All scripts pass syntax check."

check: ## Validate plugin.json structure
	@python3 -c "\
	import json, sys; \
	d = json.load(open('.claude-plugin/plugin.json')); \
	missing = [k for k in ('name','description','version') if k not in d]; \
	sys.exit(1) if missing else print('plugin.json valid:', d['name'], d['version'])"

help: ## Show available targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'
