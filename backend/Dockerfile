############################
# STEP 1 build executable
############################
FROM golang:alpine3.10 AS builder

# Create user
RUN adduser -D -g '' myuser

WORKDIR $GOPATH/src/github.com/sinfo/deck2
COPY . .

RUN apk --no-cache add ca-certificates

# Optimize by removing debug informations, compile only for linux target
# and disabling cross compilation for go >= 1.10
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/deck2 ./src/*.go


############################
# STEP 2 generate swagger specification
############################
FROM quay.io/goswagger/swagger AS swagger-builder

WORKDIR $GOPATH/src/github.com/sinfo/deck2
COPY . .

RUN swagger flatten ./swagger/swagger.json --compact -o /go/bin/swagger.json

############################
# STEP 3 build a small image
############################
FROM scratch

# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd

WORKDIR /go/bin

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/bin/deck2 /go/bin/deck2
COPY --from=swagger-builder /go/bin/swagger.json /go/bin/static/swagger.json

# Use an unprivileged user.
USER myuser

CMD ["/go/bin/deck2"]