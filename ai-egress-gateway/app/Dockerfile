# Build
FROM quay.io/centos/centos:stream9 AS builder

RUN dnf install -y golang && dnf clean all

WORKDIR /app

COPY ./main.go .
COPY ./go.mod .
COPY ./go.sum .

RUN CGO_ENABLED=0 go build -o bedrock-client main.go

# Runtime
FROM redhat/ubi8-minimal

RUN microdnf install -y curl && microdnf clean all

COPY --from=builder /app/bedrock-client /usr/local/bin/bedrock-client

EXPOSE 8080

ENV AWS_REGION=us-east-1
ENV BEDROCK_MODEL_ID=""

ENTRYPOINT ["/usr/local/bin/bedrock-client"]

