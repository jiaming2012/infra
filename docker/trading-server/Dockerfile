# Multi-stage build for Go trading server
FROM golang:1.22-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /trading-server .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /trading-server /usr/local/bin/trading-server

EXPOSE 8080
ENTRYPOINT ["trading-server"]
