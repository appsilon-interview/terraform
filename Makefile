.PHONY: help test build clean publish


help:  ## Show available commands
	@echo "Available commands:"
	@echo
	@sed -n -E -e 's|^([a-z-]+):.+## (.+)|\1@\2|p' $(MAKEFILE_LIST) | column -s '@' -t

test:  ## Run test commands
	pre-commit run --all-files --verbose --show-diff-on-failure --color always
