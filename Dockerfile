FROM golang:1.22 AS build-env

WORKDIR /vegeta-server

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN make build

FROM gcr.io/distroless/static
COPY --from=build-env /vegeta-server/bin/vegeta-server .
CMD ["./vegeta-server"]
