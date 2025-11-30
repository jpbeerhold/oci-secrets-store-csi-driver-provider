#
# OCI Secrets Store CSI Driver Provider
#
# Copyright (c) 2022 Oracle America, Inc.
# Licensed under the Universal Permissive License v 1.0
# https://oss.oracle.com/licenses/upl/
#

# Build metadata
$(eval BUILD_DATE=$(shell date -u +%Y.%m.%d.%H.%M))
BUILD_VERSION=$(BUILD_DATE)

# Image configuration
IMAGE_REPO_NAME=oci-secrets-store-csi-driver-provider

# Default registry if none is provided by GitHub workflow
ifeq "$(IMAGE_REGISTRY)" ""
	IMAGE_REGISTRY ?= ghcr.io/oracle-samples
else
	IMAGE_REGISTRY ?= ${IMAGE_REGISTRY}
endif

IMAGE_URL=$(IMAGE_REGISTRY)/$(IMAGE_REPO_NAME)

# Fixed ARM64 tag (clean and simple)
IMAGE_TAG=arm64

# Full image path
IMAGE_PATH=$(IMAGE_URL):$(IMAGE_TAG)

# Go build ldflags
LDFLAGS ?= "-X github.com/oracle-samples/oci-secrets-store-csi-driver-provider/internal/server.BuildVersion=$(BUILD_VERSION)"

.PHONY: all lint vet staticcheck sca test build docker-build docker-push docker-build-push print-docker-image-path test-coverage

all: lint test build

lint:
	golangci-lint run

vet:
	go vet ./...

staticcheck:
	# Install staticcheck if missing:
	# go install honnef.co/go/tools/cmd/staticcheck@latest
	staticcheck ./...

# Static code analysis
sca: lint vet staticcheck

test:
	go test ./...

build: cmd/server/main.go
	go build -ldflags $(LDFLAGS) -mod vendor -o dist/provider ./cmd/server/main.go

# Build OCI provider container (ARM64)
docker-build:
	docker buildx build \
		--platform=linux/arm64 \
		-t $(IMAGE_PATH) \
		-f build/Dockerfile \
		--load \
		.

# Push OCI provider container
docker-push:
	docker push $(IMAGE_PATH)

# Build and push
docker-build-push: docker-build
	docker push $(IMAGE_PATH)

# Output the image path (used by GitHub workflow)
print-docker-image-path:
	@echo $(IMAGE_PATH)

test-coverage:
	go test -coverprofile=cover.out ./...
	go tool cover -html=cover.out
