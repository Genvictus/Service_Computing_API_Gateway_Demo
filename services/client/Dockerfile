FROM golang:1.23-alpine as build

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY ./ ./
RUN go mod download

# Build
RUN CGO_ENABLED=0 GOOS=linux go build ./cmd/app

FROM golang:1.23-alpine

COPY --from=build /app/app /client-service

# Optional:
# To bind to a TCP port, runtime parameters must be supplied to the docker command.
# But we can document in the Dockerfile what ports
# the application is going to listen on by default.
# https://docs.docker.com/reference/dockerfile/#expose
EXPOSE 6969

# Run
CMD ["/client-service"]