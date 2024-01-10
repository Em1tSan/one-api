# Initial stage
FROM python:3.11 as translator

# Use ARG to get the build-time variable
ARG RUN_ENG_TRANSLATE

# Now set it as an environment variable if you need to use it at runtime
ENV RUN_ENG_TRANSLATE=$RUN_ENG_TRANSLATE

WORKDIR /app
COPY . .
RUN chmod +x ./translate-en.sh && ./translate-en.sh

FROM node:20 as web-builder


WORKDIR /web
COPY ./VERSION .
COPY --from=translator ./app/web .

WORKDIR /web/default
RUN npm install
RUN DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat VERSION) npm run build

WORKDIR /web/berry
RUN npm install
RUN DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat VERSION) npm run build

FROM golang AS go-builder

ENV GO111MODULE=on \
    CGO_ENABLED=1 \
    GOOS=linux

WORKDIR /build
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY --from=translator /app .
COPY --from=web-builder /web/build ./web/build
RUN go build -ldflags "-s -w -X 'one-api/common.Version=$(cat VERSION)' -extldflags '-static'" -o one-api

FROM alpine

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && update-ca-certificates 2>/dev/null || true

COPY --from=go-builder /build/one-api /
EXPOSE 3000
WORKDIR /data
ENTRYPOINT ["/one-api"]