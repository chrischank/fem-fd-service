FROM public.ecr.aws/docker/library/golang:1.25.7-alpine AS build

RUN go install github.com/pressly/goose/v3/cmd/goose@latest

# Set the working directory
WORKDIR /app

# Copy the go.mod and go.sum files
COPY go.mod go.sum ./

# Download the dependencies
RUN go mod download

# Copy the source code
COPY main.go ./

# Build the Go application
RUN go build -o main .

# Use a smaller base image for the final image
FROM alpine:latest

# Set environment variables
ENV DOCKERISE_VERSION v0.9.3

# Install dependencies
RUN apk update --no-cache \
    && apk add --no-cache wget openssl \
    && wget -O /usr/local/bin/dockerize https://github.com/jwilder/dockerize/releases/download/$DOCKERISE_VERSION/dockerize-alpine-linux-amd64-$DOCKERISE_VERSION.tar.gz \
    && apk del wget

# Set the working directory
WORKDIR /app

# Copy the binary from the build stage
COPY --from=build /app/main .
COPY --from=build /go/bin/goose /usr/local/bin/goose
COPY migrations ./migrations
COPY static ./static
COPY templates ./templates

# Expose port 8080
EXPOSE 8080

# Run the application
CMD ["./main"]
