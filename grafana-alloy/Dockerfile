FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    systemctl \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Grafana Alloy
# These will be provided at runtime via docker-compose or environment
ENV GCLOUD_HOSTED_METRICS_ID=""
ENV GCLOUD_HOSTED_METRICS_URL=""
ENV GCLOUD_HOSTED_LOGS_ID=""
ENV GCLOUD_HOSTED_LOGS_URL=""
ENV GCLOUD_FM_URL=""
ENV GCLOUD_FM_POLL_FREQUENCY="60s"
ENV GCLOUD_FM_HOSTED_ID=""
ENV ARCH="amd64"
ENV GCLOUD_RW_API_KEY=""

# Install Grafana Alloy
RUN /bin/sh -c "$(curl -fsSL https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-linux.sh)"

# Start Grafana Alloy service
CMD ["alloy", "run", "/etc/alloy/config.alloy"]
