COMMIT=$(shell git rev-parse HEAD)
VERSION=$(shell git describe --tags --exact-match --always)
DATE=$(shell date +'%FT%TZ%z')
CONTAINER_NAME ?= vegeta

SERVER_DIR = cmd/server

all: deps fmt lint build test

build: deps fmt
	GOFLAGS=-mod=mod CGO_ENABLED=0 go build -v -o bin/vegeta-server -a -tags=netgo \
		-ldflags '-s -w -extldflags "-static" -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)' ${SERVER_DIR}/main.go

clean:
	rm -f coverage.txt
	rm -f profile.cov
	rm -rf bin
	rm -rf vendor

deps:
	GOFLAGS=-mod=mod go mod download

update-deps:
	GOFLAGS=-mod=mod go mod verify
	GOFLAGS=-mod=mod go mod tidy

install:
	./scripts/make-install.sh

test:
	go clean -testcache
	GOFLAGS=-mod=mod go test -v -race -covermode=atomic ./...

	go clean -testcache
	GOFLAGS=-mod=mod go test -v -covermode=count -coverprofile=profile.cov ./...

fmt:
	GOFLAGS=-mod=mod go fmt ./...

validate:
	golangci-lint run

lint:
	GOFLAGS=-mod=mod go vet ./...

ineffassign:
	ineffassign .

run: build
	./bin/vegeta-server --ip=localhost --port=8000

container:
	docker build -t vegeta-server:latest .

container_stop:
	@docker rm -f '$(CONTAINER_NAME)' || true

container_run: container
	@docker run --rm -d -p 8000:80 --name '$(CONTAINER_NAME)' vegeta-server:latest

container_clean: container_stop
	@docker image rm vegeta-server:latest || true

.PHONY: all build clean deps update-deps install test fmt validate lint ineffassign run
