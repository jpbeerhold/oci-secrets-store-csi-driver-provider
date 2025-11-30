#
# OCI Secrets Store CSI Driver Provider
#
# Build and containerization Makefile
#

# ------------------------------------------------------------------------------
# Build metadata
# ------------------------------------------------------------------------------

# Build date in UTC, used as build version for tracking
$(eval BUILD_DATE=$(shell date -u +%Y.%m.%d.%H.%M))
BUILD_VERSION=$(BUILD_DATE)

# ------------------------------------------------------------------------------
# Image configuration
# ------------------------------------------------------------------------------

# Logical image name (without registry)
IMAGE_NAME ?= oci-secrets-store-csi-driver-provider

# Base image registry (hostname + optional owner/namespace)
# This can be overridden from the environment or from GitHub Actions.
# Example:
#   IMAGE_REGISTRY=ghcr.io/jpbeerhold
IMAGE_REGISTRY ?= ghcr.io/jpbeerhold

# Final image URL without tag
IMAGE_URL=$(IMAGE_REGISTRY)/$(IMAGE_NAME)

# Fixed ARM64 tag (simple and explicit)
IMAGE_TAG ?= arm64

# Full image path including tag
IMAGE_PATH=$(IMAGE_URL):$(IMAGE_TAG)

# ------------------------------------------------------------------------------
# Go build configuration
# ------------------------------------------------------------------------------

# ldflags to inject build version into the Go binary
LDFLAGS ?= "-X github.com/oracle-samples/oci-secrets-store-csi-driver-provider/internal/server.BuildVersion=$(BUILD_VERSION)"

# ------------------------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------------------------

.PHONY: all lint vet staticcheck sca test build docker-build docker-push docker-build-push print-docker-image-path test-coverage

# Default target: run lint, tests and build the binary
all: lint test build

# ------------------------------------------------------------------------------
# Static analysis and tests
# ------------------------------------------------------------------------------

lint:
	golangci-lint run

vet:
	go vet ./...

staticcheck:
	# Install staticcheck if missing:
	# go install honnef.co/go/tools/cmd/staticcheck@latest
	staticcheck ./...

# Static code analysis (runs all linters)
sca: lint vet staticcheck

# Run unit tests
test:
	go test ./...

# Build the provider binary
build: cmd/server/main.go
	go build -ldflags $(LDFLAGS) -mod vendor -o dist/provider ./cmd/server/main.go

# ------------------------------------------------------------------------------
# Docker image build and push
# ------------------------------------------------------------------------------

# Build OCI provider container image for ARM64
docker-build:
	docker buildx build \
		--platform=linux/arm64 \
		-t $(IMAGE_PATH) \
		-f build/Dockerfile \
		--load \
		.

# Push OCI provider container image
docker-push:
	docker push $(IMAGE_PATH)

# Build and push in one go
docker-build-push: docker-build
	docker push $(IMAGE_PATH)

# Output the image path (used by GitHub Actions)
print-docker-image-path:
	@echo $(IMAGE_PATH)

# ------------------------------------------------------------------------------
# Test coverage
# ------------------------------------------------------------------------------

test-coverage:
	go test -coverprofile=cover.out ./...
	go tool cover -html=cover.out
