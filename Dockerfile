FROM golang:1.11 as builder

RUN mkdir /app &&\
    chmod -R 755 /app

COPY . /app

WORKDIR /app

RUN go install

# Using debian because busybox:glibc does not include libpthread.so
FROM debian:stretch
ENV TOOL=terraform \
    VERSION=0.11.13 \
    SHA256=d57dd17c61a63073191503302ea44352ba7a274e2c7944c4b38b97477a347aa5 \
    AZURE_PLUGIN_VERSION=1.22.1

# By using ADD there is no need to install wget or curl
ADD https://releases.hashicorp.com/${TOOL}/${VERSION}/${TOOL}_${VERSION}_linux_amd64.zip ${TOOL}_${VERSION}_linux_amd64.zip
RUN echo "${SHA256}  ${TOOL}_${VERSION}_linux_amd64.zip" | sha256sum -cw &&\
    apt-get update -y &&\
    apt-get install -y unzip &&\
    unzip ${TOOL}_${VERSION}_linux_amd64.zip &&\
    rm -r ${TOOL}_${VERSION}_linux_amd64.zip &&\
    mv /terraform /usr/local/bin/terraform &&\
    apt-get clean && rm -r /var/lib/apt/lists/*

RUN mkdir -p /root/.terraform.d/plugins/linux_amd64

COPY --from=builder /go/bin/terraform-provider-azurerm /root/.terraform.d/plugins/linux_amd64/terraform-provider-azurerm_v${AZURE_PLUGIN_VERSION}

ENTRYPOINT ["terraform"]
CMD ["--help"]
