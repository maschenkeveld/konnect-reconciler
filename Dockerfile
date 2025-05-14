FROM debian:bullseye-slim

ENV DECK_VERSION=1.47.1
ENV KUBECTL_VERSION=v1.29.0

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    jq \
    ca-certificates \
    unzip \
    gnupg \
 && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
 && rm kubectl

# Install deck
RUN curl -L https://github.com/kong/deck/releases/download/v${DECK_VERSION}/deck_${DECK_VERSION}_linux_amd64.tar.gz | tar -xz \
 && mv deck /usr/local/bin/ \
 && chmod +x /usr/local/bin/deck

# Copy sync script
COPY sync.sh /sync.sh
RUN chmod +x /sync.sh

ENTRYPOINT ["/sync.sh"]
