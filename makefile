BINDIR=./bin
SRCDIR=./src
SCRIPTSDIR=./scripts
SWAGGER=./swagger
STATIC=./static
BINARY_FILENAME=deck2

.PHONY: docker
all: build-src build-scripts

build-src:
	@echo "[*] building src"
	@mkdir -p $(BINDIR)
	@go build -o $(BINDIR)/$(BINARY_FILENAME) $(SRCDIR)/*.go

	@echo "[*] generating swagger"
	@swagger flatten $(SWAGGER)/swagger.json --compact -o $(STATIC)/swagger.json

	@echo "[*] validating swagger"
	@swagger validate $(STATIC)/swagger.json -q

	@echo "DONE"

build-scripts: $(SCRIPTSDIR)/*.go
	@echo "[*] building scripts"
	@go build -o $(BINDIR)/$(notdir $(basename $^)) $^

	@echo "DONE"

test:
	@echo "[*] testing"
	@go test ./...

	@echo "DONE"

run: build-src
	@$(BINDIR)/$(BINARY_FILENAME)

clean:
	@echo "[*] cleaning"
	@go clean
	@rm -rf data $(BINDIR)

	@echo "DONE"