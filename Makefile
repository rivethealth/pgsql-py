###
# Config
###

JOBS ?= $(shell nproc)
MAKEFLAGS += -j $(JOBS) -r

PATH := $(abspath node_modules)/.bin:$(PATH)

.DELETE_ON_ERROR:
.SECONDARY:
.SUFFIXES:

LPAREN := (
RPAREN := )

###
# Clean
###

TARGET := pg_sql.egg-info build target

.PHONY: clean
clean:
	rm -fr $(TARGET)

###
# Format
###
FORMAT_SRC := $(shell find . $(TARGET:%=-not \$(LPAREN) -name % -prune \$(RPAREN)) -name '*.py')

.PHONY: format
format: target/format.target

.PHONY: test-format
test-format: target/format-test.target

target/format.target: $(FORMAT_SRC) target/node_modules.target
	mkdir -p $(@D)
	isort --profile black $(FORMAT_SRC)
	black $(FORMAT_SRC)
	node_modules/.bin/prettier --write .
	touch $@ target/format-test.target

target/format-test.target: $(FORMAT_SRC)
	mkdir -p $(@D)
	black --check $(FORMAT_SRC)
	touch $@ target/format.target

###
# Npm
###
target/node_modules.target:
	mkdir -p $(@D)
	yarn install
	> $@

###
# Pip
###
PY_SRC := $(shell find . $(TARGET:%=-not \$(LPAREN) -name % -prune \$(RPAREN)) -name '*.py')

.PHONY: install
install:
	pip3 install -e .[dev]

.PHONY: package
package: target/package.target

upload: target/package-test.target
	python3 -m twine upload target/package/*

target/package.target: setup.py README.md $(PY_SRC)
	rm -fr $(@:.target=)
	mkdir -p $(@:.target=)
	./$< bdist_wheel -d $(@:.target=) sdist -d $(@:.target=)
	> $@

target/package-test.target: target/package.target
	mkdir -p $(@D)
	python3 -m twine check target/package/*
	mkdir -p $(@D)
	> $@
