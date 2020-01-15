FROM debian:stretch-slim

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    # Install tools
    && apt-get -y install --no-install-recommends \
        procps curl wget telnet dnsutils ca-certificates vim less git bash-completion \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Enable bash completion
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc

# Install Confluent Cloud CLI (ccloud)
# https://docs.confluent.io/current/cloud/cli/install.html
ARG CCLOUD_CLI_VERSION=v0.218.0
RUN curl -L https://cnfl.io/ccloud-cli | sh -s -- -b /usr/local/bin ${CCLOUD_CLI_VERSION}
RUN ccloud completion bash >> ~/.ccloud_completion \
    && echo "source ~/.ccloud_completion" >> ~/.bashrc

# Install Confluent CLI (confluent)
# https://docs.confluent.io/current/cli/installing.html
ARG CONFLUENT_CLI_VERSION=v0.218.0
RUN curl -L https://cnfl.io/cli | sh -s -- -b /usr/local/bin ${CONFLUENT_CLI_VERSION}
RUN confluent completion bash >> ~/.confluent_completion \
    && echo "source ~/.confluent_completion" >> ~/.bashrc 

# Install Kubernetes CLI (kubectl)
# https://kubernetes.io/de/docs/tasks/tools/install-kubectl/
ARG KUBECTL_VERSION=v1.17.1
RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl
RUN kubectl completion bash >> ~/.kubectl_completion \
    && echo "source ~/.kubectl_completion" >> ~/.bashrc

# Install Kubernetes cluster and namespace manager (kubectx and kubens)
# https://github.com/ahmetb/kubectx/
ARG KUBECTX_VERSION=v0.7.1
RUN curl -L -o /usr/local/bin/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubectx \
    && chmod +x /usr/local/bin/kubectx \
    && curl -L -o /usr/local/bin/kubens https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubens \
    && chmod +x /usr/local/bin/kubens
RUN curl -L -o ~/.kubectx_completion https://raw.githubusercontent.com/ahmetb/kubectx/v0.7.1/completion/kubectx.bash \
    && echo "source ~/.kubectx_completion" >> ~/.bashrc \
    && curl -L -o ~/.kubens_completion https://raw.githubusercontent.com/ahmetb/kubectx/v0.7.1/completion/kubens.bash \
    && echo "source ~/.kubens_completion" >> ~/.bashrc

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
ARG README_URL
LABEL source.git.repository=${SOURCE_GIT_REPOSITORY} \
      source.git.commit=${SOURCE_GIT_COMMIT} \
      dockerfile.url=${DOCKERFILE_URL} \
      readme.url=${README_URL}

# Set tools related labels
LABEL ccloudcli.version=${CCLOUD_CLI_VERSION} \
      confluentcli.version=${CONFLUENT_CLI_VERSION} \
      kubectl.version=${KUBECTL_VERSION} \
      kubectx.version=${KUBECTX_VERSION}

# Set Docker image version labes
LABEL docker.image.version=${CCLOUD_CLI_VERSION}-${KUBECTL_VERSION}