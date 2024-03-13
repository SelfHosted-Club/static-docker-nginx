FROM nginx:stable

LABEL maintainer="Ilia Tivin <ilia@selfhosted.club>"

RUN apt-get update && apt-get install -y \
    openssl \
    git \
    bash \
    wget \
    socat \
    python3 \
    python3-pip \
    cron 

# Clone the acme.sh repo into the /root/.acme.sh directory and install it
RUN git clone https://github.com/acmesh-official/acme.sh.git && \
    cd acme.sh && \
    ./acme.sh --install --force --home /root/.acme.sh # Specify the home directory for acme.sh

# Although the --force flag is used, it's recommended to manage SSL renewals properly through cron.
# So, let's ensure the cron service will start with the container and set up the acme.sh renewal job
RUN echo "0 1 * * * /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null" > /etc/crontab

# Install Lexicon for DNS challenges
RUN pip3 install dns-lexicon

# Create necessary directories
RUN mkdir -p /app/config \
    && mkdir -p /app/scripts \
    && mkdir -p /app/sites

# Copy the static site files
COPY sites/ /app/sites/

# Copy the scripts
COPY scripts/generate-nginx-configs.sh /app/scripts/
COPY entrypoint.sh /app/

# Make the scripts executable
RUN chmod +x /app/scripts/*.sh /app/entrypoint.sh

# Expose port 80 and 443
EXPOSE 80 443

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
