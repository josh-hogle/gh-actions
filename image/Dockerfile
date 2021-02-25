FROM alpine:3.12

ARG GCP_SDK_VERSION=318.0.0
ARG POWERSHELL_VERSION=7.1.0

# install packages
RUN set -xe \
	&& echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories \
	&& echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories \
	&& apk update \
	&& apk upgrade \
	&& apk add --no-cache \
		bash \
		ca-certificates \
		coreutils \
		curl \
		file \
		git \
		jq \
		less \
		ncurses-terminfo-base \
		icu-libs \
		krb5-libs \
		libgcc \
		libintl \
		libssl1.1 \
		libstdc++ \
		tzdata \
		unzip \
		userspace-rcu \
		xz \
		zlib \
		libseccomp@edge \
		lttng-ust \
		docker@edgecommunity \
		docker-compose@edgecommunity \
		python3@edge \
	&& curl -L -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz \
	&& mkdir -p /opt \
	&& tar -zxvf google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz -C /opt \
	&& rm -f google-cloud-sdk-${GCP_SDK_VERSION}-linux-x86_64.tar.gz \
	&& /opt/google-cloud-sdk/bin/gcloud components install alpha beta --quiet \
	&& rm -rf /opt/google-cloud-sdk/.install/.backup \
	&& rm -rf $(find /opt/google-cloud-sdk/ -regex ".*/__pycache__") \
	&& curl -L -O https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz \
	&& mkdir -p /opt/microsoft/powershell/${POWERSHELL_VERSION} \
	&& ln -sf ${POWERSHELL_VERSION} /opt/microsoft/powershell/default \
	&& tar -zxvf powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz -C /opt/microsoft/powershell/${POWERSHELL_VERSION} \
	&& rm -f powershell-${POWERSHELL_VERSION}-linux-alpine-x64.tar.gz \
	&& chmod +x /opt/microsoft/powershell/${POWERSHELL_VERSION}/pwsh \
	&& ln -sf /opt/microsoft/powershell/default/pwsh /usr/bin/pwsh \
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
ARG IMAGE_NAME
ARG BASE_IMAGE="alpine:3.12"
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
	com.joshhogle.base_image="${BASE_IMAGE}" \
	com.joshhogle.image_name="${IMAGE_NAME}" \
	com.joshhogle.image_version="${VERSION}" \
	com.joshhogle.image_release_date="${RELEASE_DATE}" \
	com.joshhogle.commit_id="${COMMIT_ID}" \
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
