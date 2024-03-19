#!/bin/bash

echo "Starting generate-nginx-configs.sh script..."

# Remove default Nginx configuration
rm -f /etc/nginx/conf.d/default.conf
echo "Removed default Nginx configuration."

# Initialize arrays to store domain configurations
declare -a domains
declare -a plugins
declare -a exported_variables

echo "Reading domain configurations from .env file..."

# Read domain configurations from the .env file
while IFS='=' read -r key value; do
    if [[ $key =~ ^Domain\[([0-9]+)\]\.name$ ]]; then
        index=${BASH_REMATCH[1]}
        domains[$index]=$(echo $value | tr -d '"')
        echo "Domain name found: ${domains[$index]}"
    elif [[ $key =~ ^Domain\[([0-9]+)\]\.plugin$ ]]; then
        index=${BASH_REMATCH[1]}
        plugins[$index]=$(echo $value | tr -d '"')
        echo "Provider found: ${plugins[$index]}"
    elif [[ $key =~ ^Domain\[([0-9]+)\]\.([^=]+)$ ]]; then
        variable_name=${BASH_REMATCH[2]}
        variable_value=$(echo $value | tr -d '"')
        export "${variable_name}=${variable_value}"
        exported_variables+=("${variable_name}")
        echo "Exported variable: ${variable_name}=${variable_value}"
    fi
done < /app/.env

echo "Finished reading domain configurations."

# Loop through each domain
for index in "${!domains[@]}"; do
    domain="${domains[$index]}"
    plugin="${plugins[$index]}"

    echo "Processing domain: ${domain}"

    if [[ -n $domain && -n $plugin ]]; then
        echo "Using ${plugin} plugin for domain: ${domain}"

        # Register account with the specified SSL provider for the current domain
        /root/.acme.sh/acme.sh --register-account -m ${EMAIL} --server ${SSL_PROVIDER}

        # Check if the certificate directory already exists
        if [ -d "/root/.acme.sh/certificates/${domain}" ]; then
            echo "Certificate directory already exists for ${domain}."

            # Check the expiration date of the existing certificate
            expiration_info=$(/root/.acme.sh/acme.sh --info -d "${domain}" | grep "Le_NextRenewTimeStr" | awk -F '=' '{print $2}')
            expiration_date=$(date -d "$expiration_info" "+%Y-%m-%d")
            current_date=$(date +%Y-%m-%d)
            expiration_seconds=$(date -d "${expiration_date}" +%s)
            current_seconds=$(date -d "${current_date}" +%s)
            days_remaining=$(( (expiration_seconds - current_seconds) / (60*60*24) ))

            echo "SSL certificate for ${domain} expires on ${expiration_date}."

            if [ "${days_remaining}" -lt 30 ]; then
                echo "SSL certificate for ${domain} is expiring soon. Renewing..."
                /root/.acme.sh/acme.sh --renew -d ${domain} --ecc --server ${SSL_PROVIDER} --dns ${plugin}
            else
                echo "SSL certificate for ${domain} is still valid. Skipping renewal."
            fi
        else
            # Create the directory for storing the certificate files
            mkdir -p "/root/.acme.sh/certificates/${domain}"
            echo "Created directory: /root/.acme.sh/certificates/${domain}"

            # Issue SSL certificate using acme.sh with the specified DNS plugin and SSL provider
            echo "Issuing SSL certificate for ${domain} using ${plugin} and ${SSL_PROVIDER}..."
            /root/.acme.sh/acme.sh --issue --server ${SSL_PROVIDER} --dns ${plugin} -d ${domain} -d www.${domain} --dnssleep 35 -m ${EMAIL} --eab-hmac-key ${HMAC_KEY} --eab-kid ${ACCOUNT_KEY}
        fi

        # Install the issued certificate
        echo "Installing SSL certificate for ${domain}..."
        /root/.acme.sh/acme.sh --install-cert --ecc -d ${domain} \
            --key-file /root/.acme.sh/certificates/${domain}/${domain}.key \
            --fullchain-file /root/.acme.sh/certificates/${domain}/fullchain.cer

        # Generate Nginx configuration file for the domain
        cat > "/etc/nginx/conf.d/${domain}.conf" <<EOL
server {
    listen 80;
    server_name ${domain} www.${domain};

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${domain} www.${domain};

    ssl_certificate /root/.acme.sh/certificates/${domain}/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/certificates/${domain}/${domain}.key;

    location / {
        root /app/sites/${domain};
        index index.html;
    }
}
EOL
        echo "Generated Nginx configuration for ${domain}."

        echo "Continue processing the next domain..."
        sleep 2
    fi
done

echo "Finished processing all domains."

# Unset the exported variables
for variable in "${exported_variables[@]}"; do
    unset "${variable}"
    echo "Unset variable: ${variable}"
done
