##############
# DNIE SETUP #
##############

ARG BASE_IMAGE_VERSION="bookworm-slim"

FROM debian:${BASE_IMAGE_VERSION}

ARG DNIE_VERSION="1.6.8"
ARG DNIE_USER="dnie"
ARG DNIE_GROUP="dnie"
ARG DNIE_UID="1001"
ARG DNIE_GID="1001"
ARG DNIE_SUDO="false"
ARG DEFAULT_BROWSER="chromium"

ENV DEBIAN_FRONTEND noninteractive

COPY "./libpkcs11-dnie_${DNIE_VERSION}_amd64.deb" /dnie/
COPY ./dnie_headless /dnie/
COPY ./policies.json /usr/lib/firefox/distribution/policies.json
COPY ./policies.json /usr/lib/firefox-esr/distribution/policies.json
COPY ./launch /launch
RUN apt-get update -qy && \
    apt-get upgrade -qy && \
    if [ "${DNIE_SUDO}" = "true" ]; then apt-get install -qy sudo; fi && \
    apt-get install -qy usbutils pciutils ca-certificates && \
    apt-get install -qy libnss3-tools && \
    apt-get install -qy pinentry-gtk2 pcsc-tools pcscd libassuan0 && \
    apt-get install -qy firefox-esr && \
    apt-get install -qy chromium && \
    apt-get autoremove -qy && \
    rm -rf /var/lib/apt/lists/* && \
    cd /dnie/ && \
    /bin/bash /dnie/dnie_headless "libpkcs11-dnie_${DNIE_VERSION}_amd64.deb" && \
    dpkg -i "/dnie/libpkcs11-dnie-headless_${DNIE_VERSION}+local1_amd64.deb" && \
    cp "/usr/share/libpkcs11-dnie/AC RAIZ DNIE 2.crt" /usr/local/share/ca-certificates/AC_RAIZ_DNIE_2.crt && \
    groupadd -f -g "${DNIE_GID}" "${DNIE_GROUP}" && \
    useradd -c "${DNIE_USER}" -m -d "/home/${DNIE_USER}" -g "${DNIE_GROUP}" -u "${DNIE_UID}" "${DNIE_USER}" && \
    if [ "${DNIE_SUDO}" = "true" ]; then \
        echo "${DNIE_USER} ALL = NOPASSWD: ALL" > /etc/sudoers.d/dnie; \
        chmod 440 /etc/sudoers.d/dnie; \
    fi

USER "${DNIE_USER}"
WORKDIR "/home/${DNIE_USER}"
ENV HOME="/home/${DNIE_USER}"
ENV DEFAULT_BROWSER="${DEFAULT_BROWSER}"
ENTRYPOINT [ "/bin/sh" ]
CMD [ "/launch" ]

