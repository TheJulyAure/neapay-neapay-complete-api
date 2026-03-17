FROM debian:bookworm-slim

# Build arguments for Grafana Alloy installation
ARG ARCH=amd64
ARG GCLOUD_HOSTED_METRICS_ID
ARG GCLOUD_HOSTED_METRICS_URL
ARG GCLOUD_HOSTED_LOGS_ID
ARG GCLOUD_HOSTED_LOGS_URL
ARG GCLOUD_FM_URL
ARG GCLOUD_FM_POLL_FREQUENCY=60s
ARG GCLOUD_FM_HOSTED_ID
ARG GCLOUD_RW_API_KEY

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Grafana Alloy with build-time arguments
RUN GCLOUD_HOSTED_METRICS_ID="${GCLOUD_HOSTED_METRICS_ID}" \
    GCLOUD_HOSTED_METRICS_URL="${GCLOUD_HOSTED_METRICS_URL}" \
    GCLOUD_HOSTED_LOGS_ID="${GCLOUD_HOSTED_LOGS_ID}" \
    GCLOUD_HOSTED_LOGS_URL="${GCLOUD_HOSTED_LOGS_URL}" \
    GCLOUD_FM_URL="${GCLOUD_FM_URL}" \
    GCLOUD_FM_POLL_FREQUENCY="${GCLOUD_FM_POLL_FREQUENCY}" \
    GCLOUD_FM_HOSTED_ID="${GCLOUD_FM_HOSTED_ID}" \
    ARCH="${ARCH}" \
    GCLOUD_RW_API_KEY="${GCLOUD_RW_API_KEY}" \
    /bin/sh -c "$(curl -fsSL https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-linux.sh)"

# Set runtime environment variables (can be overridden at container startup)
ENV GCLOUD_HOSTED_METRICS_ID=${GCLOUD_HOSTED_METRICS_ID}
ENV GCLOUD_HOSTED_METRICS_URL=${GCLOUD_HOSTED_METRICS_URL}
ENV GCLOUD_HOSTED_LOGS_ID=${GCLOUD_HOSTED_LOGS_ID}
ENV GCLOUD_HOSTED_LOGS_URL=${GCLOUD_HOSTED_LOGS_URL}
ENV GCLOUD_FM_URL=${GCLOUD_FM_URL}
ENV GCLOUD_FM_POLL_FREQUENCY=${GCLOUD_FM_POLL_FREQUENCY}
ENV GCLOUD_FM_HOSTED_ID=${GCLOUD_FM_HOSTED_ID}
ENV ARCH=${ARCH}

# Start Grafana Alloy service
CMD ["alloy", "run", "/etc/alloy/config.alloy"]
