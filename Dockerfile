FROM envoyproxy/envoy-dev:latest

RUN apt-get update && apt-get -q install -y \
    curl wget jq python \
        python-pip \
        python-setuptools \
        groff \
        less \
        && pip --no-cache-dir install --upgrade awscli
RUN mkdir -p /etc/ssl
ADD start_envoy.sh /start_envoy.sh
ADD envoy.yaml /etc/envoy.yaml
COPY server.crt /etc/ssl/server.crt
COPY server.key /etc/ssl/server.key
COPY bundle-ca.pem /etc/ssl/bundle-ca.pem

RUN chmod +x /start_envoy.sh

ENTRYPOINT ["/bin/sh"]
EXPOSE 443
CMD ["start_envoy.sh"]