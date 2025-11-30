#
# OCI Secrets Store CSI Driver Provider
#
# Copyright (c) 2022 Oracle America, Inc. and its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#

$(eval BUILD_DATE=$(shell date -u +%Y.%m.%d.%H.%M))
$(eval GIT_TAG=$(shell git log -n 1 --pretty=format:"%H"))
BUILD_VERSION=$(GIT_TAG)-$(BUILD_DATE)

IMAGE_REPO_NAME=oci-secrets-store-csi-driver-provider

ifeq "$(IMAGE_REGISTRY)" ""
	IMAGE_REGISTRY  ?= ghcr.io/oracle-samples
else
	IMAGE_REGISTRY	?= ${IMAGE_REGISTRY}
endif

IMAGE_URL=$(IMAGE_REGISTRY)/$(IMAGE_REPO_NAME)

# Image tag is fixed to arm64 so that the image can be clearly identified as ARM64.
IMAGE_TAG=arm64
IMAGE_PATH=$(IMAGE_URL):$(IMAGE_TAG)

LDFLAGS ?= "-X github.com/oracle-samples/oci-secrets-store-csi-driver-provider/internal/server.BuildVersion=$(BUILD_VERSION)"

.PHONY : lint test build sca vet staticcheck docker-build docker-push docker-build-push print-docker-image-path test-coverage

all: lint test build

lint:
	golangci-lint run

vet:
	go vet ./...

staticcheck:
	# Install if it does not exist: `go install honnef.co/go/tools/cmd/staticcheck@latest`
	staticcheck ./...

# Static code analysis
sca: lint vet staticcheck

test:
	go test ./...

build: cmd/server/main.go
	go build -ldflags $(LDFLAGS) -mod vendor -o dist/provider ./cmd/server/main.go

docker-build:
	docker buildx build --platform=linux/arm64 -t ${IMAGE_PATH} -f build/Dockerfile --load

docker-push:
	docker push ${IMAGE_PATH}

docker-build-push: docker-build
	docker push ${IMAGE_PATH}

print-docker-image-path:
	@echo ${IMAGE_PATH}

test-coverage:
	go test -coverprofile=cover.out ./...
	go tool cover -html=cover.out
