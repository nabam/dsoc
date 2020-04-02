ARG executableName=hello-world-service

# Build container
FROM golang:1.14-alpine as builder

ARG executableName
ARG packagePath

RUN apk add --no-cache alpine-sdk zip

RUN mkdir -p /src
COPY go.sum go.mod /src/

WORKDIR /src
RUN go mod download
COPY . /src
RUN go test ./...

ENV EXECUTABLE_NAME=${executableName}
RUN go install && \
    mkdir -p /app && \
    cp -r $GOPATH/bin/$EXECUTABLE_NAME /app/service

# Runtime container
FROM alpine:3.8

LABEL maintainer="Lev Popov <leo@nabam.net>"

ARG executableName
ENV ENTRYPOINT=./${executableName}

COPY --from=builder /app /app

WORKDIR /app/
EXPOSE 8080

ENTRYPOINT ["/app/service"]
