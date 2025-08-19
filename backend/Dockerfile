#
##########################
# STEP 1 build executable
############################
FROM golang:1.23-alpine AS builder

# Create user
RUN adduser -D -g '' myuser

WORKDIR /app
COPY . .

RUN apk --no-cache add ca-certificates

# Optimize by removing debug informations, compile only for linux target
# and disabling cross compilation for go >= 1.10
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/deck2 ./src/*.go


############################
# STEP 2 generate swagger specification
############################
FROM quay.io/goswagger/swagger AS swagger-builder

WORKDIR /app
COPY . .

RUN swagger flatten ./swagger/swagger.json --compact -o /app/swagger.json

############################
# STEP 3 build a small image
############################
FROM scratch

# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd

WORKDIR /app

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/deck2 /app/deck2
COPY --from=swagger-builder /app/swagger.json /app/static/swagger.json

# Use an unprivileged user.
USER myuser

CMD ["/app/deck2"]
