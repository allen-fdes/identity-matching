current_dir = $(shell pwd)

PROJECT = identity_matching
COMMANDS = cmd/match-identities

PKG_OS = darwin linux

DOCKERFILES = Dockerfile:$(PROJECT)
DOCKER_ORG = "srcd"

# Including ci Makefile
CI_REPOSITORY ?= https://github.com/src-d/ci.git
CI_BRANCH ?= v1
CI_PATH ?= .ci
MAKEFILE := $(CI_PATH)/Makefile.main
$(MAKEFILE):
	git clone --quiet --depth 1 -b $(CI_BRANCH) $(CI_REPOSITORY) $(CI_PATH);
-include $(MAKEFILE)

export GITHUB_TEST_TOKEN=a7f979a7c45e7d3517ad7eeeb8cba5e16e813aef
export GITLAB_TEST_TOKEN=RZtZsqZ3FckbHB-YRYzG
export BITBUCKET_TEST_TOKEN=JOHRfFo9NG2npndvCXmkD82D

fix-style:
	gofmt -s -w .
	goimports -w .

.ONESHELL:
.POSIX:
check-style:
	golint -set_exit_status ./...
	# Run `make fix-style` to fix style errors
	test -z "$$(gofmt -s -d .)"
	test -z "$$(goimports -d .)"
	go vet
	pycodestyle --max-line-length=99 $(current_dir)/research $(current_dir)/parquet2sql

check-generate:
	# -modtime flag is required to make `make check-generate` work.
	# Otherwise, the regenerated file has a different modtime value.
	# `1562752805` corresponds to 2019-07-10 12:00:05 CEST.
	esc -pkg idmatch -prefix blacklists -modtime 1562752805 blacklists | \
		diff --ignore-matching-lines="\/\/ Code generated by \".*\"; DO NOT EDIT\." blacklists.go - \
 		# Run `go generate` to update autogenerated files

install-dev-deps:
	pip3 install --user pycodestyle==2.5.0
	go get -v golang.org/x/lint/golint github.com/mjibson/esc golang.org/x/tools/cmd/goimports

.PHONY: check-style check-generate dev-deps fix-style
