# Useage:
# docker buildx build --output type=local,dest=development/ --file utils/obfuscate.Dockerfile [--build-arg PACKAGE=<packages>] .

ARG PLATFORM_ARGS="--platform windows.x86_64 --platform linux.x86_64 --platform darwin.x86_64"
ARG EXPIRE_DATE=366
ARG EXTENSIONS="./extensions/"
ARG PACKAGES

FROM python:3.12-slim AS python-3.12
ARG PLATFORM_ARGS
ARG EXPIRE_DATE
ARG EXTENSIONS
ARG PACKAGES
WORKDIR /workspaces/development/
COPY ${EXTENSIONS} extensions/
RUN python -m pip install --no-cache-dir pyarmor && \
    python -m pip install --no-cache-dir pyarmor.cli.core.windows && \
    python -m pip install --no-cache-dir pyarmor.cli.core.themida && \
    python -m pip install --no-cache-dir pyarmor.cli.core.linux && \
    python -m pip install --no-cache-dir pyarmor.cli.core.darwin && \
    python -m pyarmor.cli cfg plugins + "MultiPythonPlugin"
RUN if [ -z "${PACKAGES:-}" ] || [ "${PACKAGES}" = "all" ]; then \
        PACKAGES=$(find extensions/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); \
    fi && \
    for PACKAGE in ${PACKAGES}; do \
        mkdir -p obfuscated/${PACKAGE} && cp -r extensions/${PACKAGE}/ obfuscated/ && \
        python -m pyarmor.cli -d generate ${PLATFORM_ARGS} -e ${EXPIRE_DATE} -O obfuscated/ -r -i extensions/${PACKAGE}/; \
    done

FROM python:3.11-slim AS python-3.11
ARG PLATFORM_ARGS
ARG EXPIRE_DATE
ARG EXTENSIONS
ARG PACKAGES
WORKDIR /workspaces/development/
COPY ${EXTENSIONS} extensions/
RUN python -m pip install --no-cache-dir pyarmor && \
    python -m pip install --no-cache-dir pyarmor.cli.core.windows && \
    python -m pip install --no-cache-dir pyarmor.cli.core.themida && \
    python -m pip install --no-cache-dir pyarmor.cli.core.linux && \
    python -m pip install --no-cache-dir pyarmor.cli.core.darwin && \
    python -m pyarmor.cli cfg plugins + "MultiPythonPlugin"
RUN if [ -z "${PACKAGES:-}" ] || [ "${PACKAGES}" = "all" ]; then \
        PACKAGES=$(find extensions/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); \
    fi && \
    for PACKAGE in ${PACKAGES}; do \
        mkdir -p obfuscated/${PACKAGE} && cp -r extensions/${PACKAGE}/ obfuscated/ && \
        python -m pyarmor.cli -d generate ${PLATFORM_ARGS} -e ${EXPIRE_DATE} -O obfuscated/ -r -i extensions/${PACKAGE}/; \
    done

FROM python:3.12-slim AS merge
ARG PACKAGES
WORKDIR /workspaces/development/
COPY --from=python-3.12 /workspaces/development/obfuscated/ obfuscated/3.12/
COPY --from=python-3.11 /workspaces/development/obfuscated/ obfuscated/3.11/
RUN python -m pip install --no-cache-dir pyarmor
RUN if [ -z "${PACKAGES:-}" ] || [ "${PACKAGES}" = "all" ]; then \
        PACKAGES=$(find obfuscated/ -mindepth 2 -maxdepth 2 -type d -exec basename {} \;); \
    fi && \
    for PACKAGE in ${PACKAGES}; do \
        python -m pyarmor.cli.merge -O obfuscated/${PACKAGE} obfuscated/*/${PACKAGE}; \
        rm -rf obfuscated/*/${PACKAGE} || true; \
    done;\
    find obfuscated/ -mindepth 1 -maxdepth 1 -type d -empty -exec rm -rf {} \; || true;

FROM scratch
COPY --from=merge /workspaces/development/obfuscated/ /obfuscated/