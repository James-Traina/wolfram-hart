.PHONY: test lint check

test: ## Run all 100 tests (requires wolframscript)
	bash tests/run-tests.sh

lint: ## Syntax-check all shell scripts
	@for f in skills/wolfram-hart/scripts/*.sh tests/run-tests.sh tests/helpers.sh tests/batch-*.sh; do \
		bash -n "$$f" && printf '  ok  %s\n' "$$f" || exit 1; \
	done
	@echo "All scripts pass syntax check."

check: ## Validate plugin.json and component frontmatter
	@python3 -c "\
	import json, sys; \
	d = json.load(open('.claude-plugin/plugin.json')); \
	missing = [k for k in ('name','description','version') if k not in d]; \
	sys.exit(1) if missing else print('plugin.json valid:', d['name'], d['version'])"
	@for f in commands/*.md; do \
		head -30 "$$f" | grep -q '^description:' \
			|| { echo "FAIL: $$f missing 'description'"; exit 1; }; \
	done
	@for f in agents/*.md; do \
		for key in name description model color; do \
			head -40 "$$f" | grep -q "^$$key:" \
				|| { echo "FAIL: $$f missing '$$key'"; exit 1; }; \
		done; \
	done
	@echo "All frontmatter valid."

help: ## Show available targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'
