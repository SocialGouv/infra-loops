ARG UBUNTU_VERSION=22.04

FROM ubuntu:$UBUNTU_VERSION as downloader
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    curl \
    ca-certificates \
    wget \
    git \
  && rm -rf /var/lib/apt/lists/*

FROM downloader as kubectl
ARG KUBECTL_VERSION=v1.25.0
ENV KUBECTL_VERSION=$KUBECTL_VERSION
RUN curl --fail -sL https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

FROM downloader as helm
ARG HELM_VERSION=v3.9.3
ENV HELM_VERSION=$HELM_VERSION
RUN curl --fail -sL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xz -C /tmp/ \
  && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm \
  && rm -r /tmp/linux-amd64

FROM downloader as rollout-status
ARG ROLLOUT_STATUS_VERSION=v1.13.4
ENV ROLLOUT_STATUS_VERSION=$ROLLOUT_STATUS_VERSION
RUN curl --fail -sL https://github.com/socialgouv/rollout-status/releases/download/${ROLLOUT_STATUS_VERSION}/rollout-status-${ROLLOUT_STATUS_VERSION}-linux-amd64 > /tmp/rollout-status \
  && mv /tmp/rollout-status /usr/local/bin/rollout-status \
  && chmod +x /usr/local/bin/rollout-status

FROM downloader as gomplate
ARG GOMPLATE_VERSION=v1.9.0
ENV GOMPLATE_VERSION=$GOMPLATE_VERSION
RUN curl -sL https://github.com/SocialGouv/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64 > /tmp/gomplate \
  && mv /tmp/gomplate /usr/local/bin/gomplate \
  && chmod +x /usr/local/bin/gomplate

FROM ubuntu:$UBUNTU_VERSION as node
ARG NODE_VERSION=18
ENV NODE_VERSION=$NODE_VERSION
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    ca-certificates \
    git \
    libgraph-easy-perl \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && \
  apt-get install -yq --no-install-recommends \
    wget \
    && wget -qO- https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1001 ubuntu && useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1001 ubuntu

WORKDIR /app
RUN chown 1001:1001 /app

USER 1001


FROM node as packages
COPY --chown=1001:1001 package.json /app/
RUN node -e "fs.writeFileSync('/app/package.json', JSON.stringify({ ...JSON.parse(fs.readFileSync('/app/package.json')), version: '0.0.0' }));"


FROM node as builder
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV

COPY --from=packages --chown=1001:1001 /app/package.json /app/
COPY --chown=1001:1001 package.json yarn.lock .yarnrc.yml /app/
COPY --chown=1001:1001 .yarn .yarn

RUN mkdir -p src
RUN yarn install --immutable \
  && yarn cache clean
RUN rm -rf src

COPY --chown=1001:1001 . /app/

## CLI
FROM node as job

COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /usr/local/bin/helm /usr/local/bin/helm
COPY --from=rollout-status /usr/local/bin/rollout-status /usr/local/bin/rollout-status
COPY --from=gomplate /usr/local/bin/gomplate /usr/local/bin/gomplate

ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV

ENV GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

USER 1001

WORKDIR /app

COPY --from=builder --chown=1001:1001 /app/ /app/

ENTRYPOINT ["/app/node_modules/.bin/foundernetes"]
CMD ["help"]