.PHONY: clean clean-test clean-pyc clean-build docs test help typecheck quality
.DEFAULT_GOAL := default

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

default: typecheck test ## run default typechecking and tests

typecheck: ## run mypy against project
	mypy .

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 op_env tests

test: ## run tests quickly with the default Python
	pytest

test-all: ## run tests on every Python version with tox
	tox

quality:  ## run precommit quality checks
	bundle exec overcommit --run

coverage: ## check code coverage quickly with the default Python
	coverage run --source op_env -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/op_env.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ op_env
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: dist ## package and upload a release
	twine upload dist/*

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python setup.py install

update_from_cookiecutter: ## Bring in changes from template project used to create this repo
	IN_COOKIECUTTER_PROJECT_UPGRADER=1 cookiecutter_project_upgrader || true
	git checkout cookiecutter-template && git push && (git checkout main; bundle exec overcommit --sign)
	git checkout main && bundle exec overcommit --sign && git pull && (git checkout -b update-from-cookiecutter-$$(date +%Y-%m-%d-%H%M); bundle exec overcommit --sign)
	git merge cookiecutter-template || true
	@echo
	@echo "Please resolve any merge conflicts below and push up a PR with:"
	@echo
	@echo '   gh pr create --title "Update from cookiecutter" --body "Automated PR to update from cookiecutter boilerplate"'
	@echo
	@echo
