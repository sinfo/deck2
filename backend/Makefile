BINDIR=./bin
SRCDIR=./src
SCRIPTSDIR=./scripts
SWAGGER=./swagger
STATIC=./static
BINARY_FILENAME=deck2

export GO111MODULE=on

all: help

## build                     : Compile source code and generate swagger specifications.
.PHONY: build
build: build-src build-swagger

## build-src                 : Compile source code.
.PHONY: build-src
build-src:
	@echo "[*] building source"

	@mkdir -p $(BINDIR)
	@go build -o $(BINDIR)/$(BINARY_FILENAME) $(SRCDIR)/*.go

## build-swagger             : Generate and validate swagger specifications.
.PHONY: build-swagger
build-swagger:
	@echo "[*] generating swagger"
	@mkdir -p $(STATIC)
	@swagger flatten $(SWAGGER)/endpoints/swagger.json --compact -o $(STATIC)/swagger.json

	@echo "[*] validating swagger"
	@swagger validate $(STATIC)/swagger.json -q

## build-scripts             : Compile dev script.
.PHONY: build-scripts
build-scripts: $(SCRIPTSDIR)/*.go
	@echo "[*] building scripts"

	@go build -o $(BINDIR)/$(notdir $(basename $^)) $^

## test                      : Run tests.
.PHONY: test
test:
	@echo "[*] testing"

	@go test ./...

## run                       : Run deck2.
run: build-src build-swagger
	@$(BINDIR)/$(BINARY_FILENAME)

## docker-test               : Run docker tests.
.PHONY: docker-test
docker-test:
	@echo "\n[*] building image\n"
	@docker-compose -f ../docker-compose.test.yml -p deck2-testing build

	@echo "\n[*] running image\n"
	@docker-compose -f ../docker-compose.test.yml -p deck2-testing up --abort-on-container-exit

.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

.PHONY : clean
clean:
	@echo "[*] cleaning"

	@go clean
	@rm -rf data $(BINDIR)

## To run in production run the binary with --production
