FROM flink:2.0.1-scala_2.12-java17

USER root

# Install Python + build tools + full JDK + venv support
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev \
    build-essential \
    curl \
    ca-certificates \
    openjdk-17-jdk-headless \
    cmake \
    ninja-build \
    zip \
  && rm -rf /var/lib/apt/lists/*

# Detect real JDK path via javac and expose it as JAVA_HOME
# Also create /opt/java/openjdk symlink for build scripts expecting this location.
RUN set -eux; \
    JDK_DIR="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"; \
    echo "Detected JDK at: ${JDK_DIR}"; \
    echo "Listing JDK_DIR:"; ls -la "${JDK_DIR}"; \
    echo "Listing JDK include:"; ls -la "${JDK_DIR}/include" || true; \
    mkdir -p /opt/java; \
    rm -rf /opt/java/openjdk; \
    ln -s "${JDK_DIR}" /opt/java/openjdk; \
    echo "Listing /opt/java/openjdk:"; ls -la /opt/java/openjdk; \
    echo "Listing /opt/java/openjdk/include:"; ls -la /opt/java/openjdk/include; \
    test -d /opt/java/openjdk/include

ENV JAVA_HOME=/opt/java/openjdk

# Create a virtual environment for Python dependencies (avoids PEP 668 restrictions)
ENV VENV_PATH=/opt/venv
RUN python3 -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Upgrade pip inside venv and install uv there
RUN pip install --no-cache-dir -U pip setuptools wheel \
 && pip install --no-cache-dir uv

WORKDIR /app
COPY pyproject.toml /app/pyproject.toml
COPY uv.lock /app/uv.lock
COPY processing/ /app/processing/

RUN /opt/venv/bin/pip install --no-cache-dir "setuptools<81"

SHELL ["/bin/bash", "-lc"]
RUN /opt/venv/bin/uv pip install --python /opt/venv/bin/python \
    --no-cache -r <(/opt/venv/bin/uv pip compile --group processing /app/pyproject.toml)

# Make Flink use the venv by default (исправлено: было /app/venv)
ENV PATH="/opt/venv/bin:${PATH}"

# -----------------------------
# JARs: split between lib and plugins
# -----------------------------
# 1) Put non-filesystem connector jars into /opt/flink/lib
#    (Kafka connector, kafka-clients, parquet)
RUN mkdir -p /opt/flink/lib
COPY processing/jars/flink-connector-kafka-4.0.1-2.0.jar /opt/flink/lib/
COPY processing/jars/kafka-clients-3.9.1.jar /opt/flink/lib/
COPY processing/jars/flink-sql-parquet-2.0.1.jar /opt/flink/lib/
COPY processing/jars/hadoop-common-3.3.6.jar /opt/flink/lib/
COPY processing/jars/hadoop-auth-3.3.6.jar /opt/flink/lib/
COPY processing/jars/hadoop-client-api-3.3.6.jar /opt/flink/lib/
COPY processing/jars/hadoop-client-runtime-3.3.6.jar /opt/flink/lib/

# 2) Put the GCS filesystem plugin into /opt/flink/plugins/gs-fs-hadoop
#    This is crucial so Flink can resolve the "gs://" scheme.
RUN mkdir -p /opt/flink/plugins/gs-fs-hadoop
COPY processing/jars/flink-gs-fs-hadoop-2.0.1.jar /opt/flink/plugins/gs-fs-hadoop/

# (опционально) sanity check: показать, что jar реально на месте
RUN ls -la /opt/flink/lib && ls -la /opt/flink/plugins/gs-fs-hadoop

WORKDIR /opt/flink/usrlib

# Flink runs as flink user
USER flink