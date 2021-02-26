.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os
import re
import sys
import webbrowser
from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

define generate_footer
Documentation
\n=============
\n
.. toctree::\n
\t:maxdepth: 1\n
\tcaption: Getting Started\n
\n
\tinstallation\n
\texamples\n
\n
.. toctree::\n
\t:maxdepth: 1\n
\t:caption: Help & Reference\n
\n
\thistory\n
\tmodules\n
\tcontributing\n
\tauthors\n
\tlicense\n
endef
export INDEX_FOOTER=$(value generate_footer)

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

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
	rm -rf data

lint: ## check style with flake8
	pre-commit run --all-files

test: ## run tests quickly with the default Python
	pytest --no-cov -n 4 -v

coverage: ## check code coverage quickly with the default Python
	coverage run --source hydrodata -m pytest -v
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

apidocs: ## generate API docs
	rm -f docs/hydrodata.rst
	rm -f docs/modules.rst
	sed '/Installation/IQ' README.rst > docs/index.rst
	echo $$INDEX_FOOTER >> docs/index.rst
	sed -i 's/\t/    /g' docs/index.rst
	sphinx-apidoc -o docs/ -f -H "API Reference" hydrodata

docs: apidocs ## generate Sphinx HTML documentation, including API docs
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python -m pip install . --no-deps
