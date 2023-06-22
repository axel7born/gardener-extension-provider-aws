############# builder
FROM golang:1.19.4 AS builder

WORKDIR /go/src/github.com/gardener/gardener-extension-provider-aws
COPY . .
RUN make install

# Use this to build an image that can be debugged via remote debugging
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -gcflags="all=-N -l" -a -o /go/bin/gardener-extension-provider-aws ./cmd/gardener-extension-provider-aws
RUN go install github.com/go-delve/delve/cmd/dlv@latest

############# base
FROM gcr.io/distroless/static-debian11:nonroot AS base

############# gardener-extension-provider-aws
# FROM base AS gardener-extension-provider-aws
# dlv doesn't work in the distroless image. Use golang image instead.
FROM golang:1.20.4 AS gardener-extension-provider-aws
WORKDIR /

COPY charts /charts
COPY --from=builder /go/bin/gardener-extension-provider-aws /gardener-extension-provider-aws
COPY --from=builder /go/bin/dlv /
ENTRYPOINT ["/gardener-extension-provider-aws"]

############# gardener-extension-admission-aws
FROM base as gardener-extension-admission-aws
WORKDIR /

COPY --from=builder /go/bin/gardener-extension-admission-aws /gardener-extension-admission-aws
ENTRYPOINT ["/gardener-extension-admission-aws"]
