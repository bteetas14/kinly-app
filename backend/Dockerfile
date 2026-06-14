FROM golang:1.26-alpine AS build

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/kinly-api ./cmd/api

FROM alpine:3.22
RUN adduser -D -H kinly
USER kinly
COPY --from=build /out/kinly-api /kinly-api
EXPOSE 8080
ENTRYPOINT ["/kinly-api"]
