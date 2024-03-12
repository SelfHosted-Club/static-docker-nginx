# Static site hosting on nginx with certbot and RFC-2136

I prefer static sites as it's easier to host and secure over CMS and dynamic ones.
This is a container that will be used in a pipeline that will be created everytime I run an update and push changes on my site - this is for production use and not for testing as this one uses certbot to generate certificates at run time - if you restart the container lots of times you will get throttled by Let's Encrypt.

## How to use?

1. Clone the repository to your chosen directory or fork it to your own repo.
2. Put your static website files into the `sites` directory in the format `domain.tld`, scripts will grab the folder name and use that to request certificates.
3. Update `config/certbot.ini` with your RFC-2136 configuration.

### Building an image

To build the container, run:
```shell
docker build --no-cache -t static-nginx .
```

### Running the container

Replace the EMAIL variable with your email.

```
docker run -d -e EMAIL=your@email.com -p 80:80 -p 443:443 --name static-site-webserver static-nginx
```
The container will take 2 minutes to start as it waits for certificates.

#### Successful run:
```txt
selfhosted@PC My sites % docker run -d -p 80:80 -p 443:443 -e EMAIL=your@email.com --name nginx-certbot nginx-certbot
29deb02f36404e8da793a4ddf4b44115e8ed0807b7463c48f64d30c5165d7f47
selfhosted@PC My sites % docker logs -f nginx-certbot
Running generate-nginx-configs.sh script...
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Simulating a certificate request for selfhosted.club and www.selfhosted.club
Waiting 60 seconds for DNS changes to propagate
The dry run was successful.
Dry run succeeded for selfhosted.club. Proceeding with certificate issuance.
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for selfhosted.club and www.selfhosted.club
Waiting 60 seconds for DNS changes to propagate
Hook 'deploy-hook' reported error code 1
Hook 'deploy-hook' ran with error output:
 2024/03/12 06:18:38 [notice] 13#13: signal process started
 2024/03/12 06:18:38 [error] 13#13: open() "/var/run/nginx.pid" failed (2: No such file or directory)
 nginx: [error] open() "/var/run/nginx.pid" failed (2: No such file or directory)

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/selfhosted.club/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/selfhosted.club/privkey.pem
This certificate expires on 2024-06-10.
These files will be updated when the certificate renews.
NEXT STEPS:
- The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Starting Nginx...
```

The error above ` nginx: [error] open() "/var/run/nginx.pid" failed (2: No such file or directory)` is safe to ignore, as nginx hasn't been started yet.

## What happens in the backend?

1. Package updates and isntallation of certbot.
2. Copying all directories from `sites` directory, `config` and scripts from `scripts`
3. `entrypoint.sh` calls `scripts/generate-nginx-configs.sh` which:
    * Does a dry run for certificate issue, if that fails then a self-generated certificate is installed.
    * If dry run succeeds, we continue to ask for a certificate
    * Generation of simple nginx configuration to listen on `domain.tld` and `www.domain.tld`.
4. renewal hook creation to restart nginx on certificate renewal.
5. start nginx
