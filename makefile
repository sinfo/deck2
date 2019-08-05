BINDIR=./bin
SRCDIR=./src
SWAGGER=./swagger
STATIC=./static
BINARY_FILENAME=deck2

.PHONY: docker
all: build

build:
	mkdir -p $(BINDIR)
	go build -o $(BINDIR)/$(BINARY_FILENAME) $(SRCDIR)/*.go

	# validate and generate swagger documentation
	swagger flatten $(SWAGGER)/swagger.json --compact -o $(STATIC)/swagger.json
	swagger validate $(STATIC)/swagger.json

test:
	go test ./... -v

run: build
	$(BINDIR)/$(BINARY_FILENAME)

clean:
	go clean
	rm -rf data $(BINDIR)