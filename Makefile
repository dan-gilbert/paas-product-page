
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

node_modules: ## reinstall sass dependencies
	@which -s npm || (echo 'npm is required to install the upstream sass dependencies. Install node js + npm.' && false)
	npm install

vendor: # reinstall ruby dependencies
	@which -s bundle || (echo 'bundler is required to install application dependencies. Install Ruby + bundler' && false)
	bundle install --path vendor/bundle

.PHONY: test
test: vendor ## Run tests
	bundle exec rspec --format doc

.PHONY: dev
dev: vendor node_modules ## Run the application locally in development mode
	RESTCLIENT_LOG=stdout bundle exec rackup

.PHONY: clean
clean: ## Clean up
	rm -rf node_modules
	rm -rf vendor
