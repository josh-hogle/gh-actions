#
# GH Actions container build image
#
FROM alpine:3.13

ARG GCP_SDK_VERSION=329.0.0
ARG POWERSHELL_VERSION=7.1.2
ARG GLIBC_VER=2.31-r0

# install packages
RUN set -xe \
	&& echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories \
	&& echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories \
	&& apk update \
	&& apk upgrade \
	&& apk add --no-cache \
		# main packages
		bash \
		binutils \
		build-base \
		ca-certificates \
		coreutils \
		curl \
		file \
		gcc \
		git \
		jq \
		less \
		ncurses-terminfo-base \
		icu-libs \
		krb5-libs \
		libffi-dev \
		libgcc \
		libintl \
		libssl1.1 \
		libstdc++ \
		lttng-ust \
		make \
		musl-dev \
		openssl-dev \
		tzdata \
		unzip \
		userspace-rcu \
		xz \
		zlib \
		# edge packages
		libseccomp@edge \
		python3@edge \
		python3-dev@edge \
		py3-pip@edge \
		# edge community packages
		docker@edgecommunity \
		docker-compose@edgecommunity \
		go@edgecommunity \
	&& pip3 --no-cache-dir install -U pip \
	&& cd /tmp \
	# AWS CLIv2
	&& curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
	&& curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
	&& apk add --no-cache \
		glibc-${GLIBC_VER}.apk \
		glibc-bin-${GLIBC_VER}.apk \
	&& curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
	# GCP cloud SDK
	&& curl -L -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz \
	&& mkdir -p /opt \
	&& tar -zxvf google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz -C /opt \
	&& rm -f google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz \
	&& /opt/google-cloud-sdk/bin/gcloud components install alpha beta --quiet \
	&& rm -rf /opt/google-cloud-sdk/.install/.backup \
	&& rm -rf $(find /opt/google-cloud-sdk/ -regex ".*/__pycache__") \
	# Azure CLI
	&& pip3 --no-cache-dir install azure-cli \
	# PowerShell
	&& curl -L -O https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz \
	&& mkdir -p /opt/microsoft/powershell/${POWERSHELL_VERSION} \
	&& ln -sf ${POWERSHELL_VERSION} /opt/microsoft/powershell/default \
	&& tar -zxvf powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz -C /opt/microsoft/powershell/${POWERSHELL_VERSION} \
	&& rm -f powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz \
	&& chmod +x /opt/microsoft/powershell/${POWERSHELL_VERSION}/pwsh \
	&& ln -sf /opt/microsoft/powershell/default/pwsh /usr/bin/pwsh \
	# Cleanup
	&& rm -rf /tmp/* /var/tmp/* /usr/local/src /var/cache/apk/* 

# add files to image
COPY files /

# finish image configuration
RUN set -xe \
	&& chmod 0755 /entrypoint.sh \
	&& chmod 0700 /root \
	&& rm -f /etc/profile.d/color_prompt \
	&& update-ca-certificates \
	&& sed -i -e 's|/bin/ash|/bin/bash|g' /etc/passwd

# Set entry point
ENTRYPOINT [ "/entrypoint.sh" ]

# Configure default command
CMD [ "/bin/bash", "-l" ]

# Required build arguments
ARG BASE_IMAGE="alpine:3.13"
ARG IMAGE_NAME
ARG VERSION
ARG RELEASE_DATE
ARG CREATED_TIMESTAMP
ARG COMMIT_ID
ARG IMAGE_INFO_URL="https://github.com/josh-hogle/gh-actions"
ARG IMAGE_SOURCE_URL="${IMAGE_INFO_URL}"
ARG IMAGE_DOC_URL="${IMAGE_INFO_URL}"

# Image build metadata
LABEL \
	maintainer="Josh Hogle <josh@joshhogle.com>" \
	com.joshhogle.image.base="${BASE_IMAGE}" \
	com.joshhogle.image.name="${IMAGE_NAME}" \
	com.joshhogle.image.version="${VERSION}" \
	com.joshhogle.image.release_date="${RELEASE_DATE}" \
	com.joshhogle.source.url="${IMAGE_SOURCE_URL}" \
	com.joshhogle.source.commit_id="${COMMIT_ID}" \
	org.opencontainers.image.vendor="Josh Hogle" \
	org.opencontainers.image.title="GitHub Actions image" \
	org.opencontainers.image.description="Docker image used by GitHub Actions library" \
	org.opencontainers.image.authors="Josh Hogle <josh@joshhogle.com>" \
	org.opencontainers.image.licenses="Apache-2.0" \
	org.opencontainers.image.version="${VERSION}" \
	org.opencontainers.image.documentation="${IMAGE_DOC_URL}" \
	org.opencontainers.image.url="${IMAGE_INFO_URL}" \
	org.opencontainers.image.source="${IMAGE_SOURCE_URL}" \
	org.opencontainers.image.revision="${COMMIT_ID}" \
	org.opencontainers.image.created="${CREATED_TIMESTAMP}"
