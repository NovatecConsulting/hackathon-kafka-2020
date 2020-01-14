FROM debian:stretch-slim

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    # Install tools
    && apt-get -y install --no-install-recommends \
        procps curl wget telnet dnsutils vim less git bash-completion \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Install Confluent Cloud CLI (ccloud)
# https://docs.confluent.io/current/cloud/cli/install.html
ARG CCLOUD_VERSION=0.218.0
RUN curl -L https://cnfl.io/ccloud-cli | sh -s -- -b /usr/local/bin ${CCLOUD_VERSION}
RUN ccloud completion bash >> /etc/profile.d/ccloud_completion

# Install Kubernetes CLI (kubectl)
# https://kubernetes.io/de/docs/tasks/tools/install-kubectl/
ARG KUBECTL_VERSION=v1.17.0
RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Install Kubernetes cluster and namespace manager (kubectx and kubens)
# https://github.com/ahmetb/kubectx/
ARG KUBECTX_VERSION=v0.7.1
RUN curl -L -o /usr/local/bin/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubectx \
    && chmod +x /usr/local/bin/kubectx \
    && curl -L -o /usr/local/bin/kubens https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubens \
    && chmod +x /usr/local/bin/kubens

# Install pid1 init daemon
ARG PID1_VERSION=0.1.2.0
RUN curl -L https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["/bin/bash"]

# Set workdir
WORKDIR /root

# Set Git related labels
ARG SOURCE_GIT_REPOSITORY
ARG SOURCE_GIT_COMMIT
ARG DOCKERFILE_URL
LABEL source.git.repository=${SOURCE_GIT_REPOSITORY} \
      source.git.commit=${SOURCE_GIT_COMMIT} \
      dockerfile.url=${DOCKERFILE_URL}