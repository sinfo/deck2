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
	go test -c $(SRCDIR)/models -o $(BINDIR)/models.test
	go test -c $(SRCDIR)/mongodb -o $(BINDIR)/mongodb.test
	go test -c $(SRCDIR)/router -o $(BINDIR)/router.test

	# validate and generate swagger documentation
	swagger flatten $(SWAGGER)/swagger.json --compact -o $(STATIC)/swagger.json
	swagger validate $(STATIC)/swagger.json

test:
	./bin/mongodb.test
	./bin/router.test

run: build
	$(BINDIR)/$(BINARY_FILENAME)

clean:
	go clean
	rm -rf data $(BINDIR)