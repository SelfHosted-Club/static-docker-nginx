# Static site hosting on nginx with acme.sh and RFC-2136 support

I prefer static sites as it's easier to host and secure over CMS and dynamic ones.
This is a container that will be used in a pipeline that will be created everytime I run an update and push changes on my site - this is for production use and not for testing as this one uses acme.sh to generate certificates at run time - if you restart the container lots of times you will get throttled by the SSL providers.

## How to use?

1. Clone the repository to your chosen directory or fork it to your own repo.
2. Put your static website files into the `sites` directory in the format `domain.tld`, scripts will grab the folder name and use that to request certificates.
3. Update `env` file with your configuration.

### Building an image

To build the container, run:
```shell
docker build --no-cache -t static-nginx .
```

### Running the container

Replace the variables with your email.
For provider configuration, visit [acme.sh documentation](https://github.com/acmesh-official/acme.sh)

> You must have the env file to run this.


env file format is:
```text
DOMAIN[x].Variable=Value
```

The variable is passed directly to the runtime, so if acme.sh needs a variable such as CF_API_KEY then you should configure DOMAIN[x].CF_API_KEY.

#### Docker command
```shell
docker run -d -p 80:80 -p 443:443 -v acme_conf:/root/.acme.sh --name static-site-webserver static-nginx
```

#### Docker-compose

```yaml
version: "3.8"
services:
  websites:
    container_name: static-site-webserver
    image: YOUR_IMAGE
    volumes:
      - acme_conf:/root/.acme.sh
    env_file:
      - env
    ports:
      - 80:80
      - 443:443

volumes:
  acme_conf:
```

The container will run through the entire configuration and certificate request before it starts, so it really depends on the amount of domains you have.

#### Successful run:
```txt
...
nginx-websites  | Starting Nginx...
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: using the "epoll" event method
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: nginx/1.24.0
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: built by gcc 10.2.1 20210110 (Debian 10.2.1-6) 
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: OS: Linux 5.15.0-101-generic
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: getrlimit(RLIMIT_NOFILE): 1048576:1048576
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: start worker processes
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: start worker process 5928
nginx-websites  | 2024/03/19 16:38:01 [notice] 5927#5927: start worker process 5929
...
```


## What happens in the backend?

1. Package updates and isntallation of acme.sh.
2. Copying all directories from `sites` directory and scripts.
3. `entrypoint.sh` calls `scripts/generate-nginx-configs.sh` which:
    * Generation of simple nginx configuration to listen on `domain.tld` and `www.domain.tld`.
4. renewal hook creation to restart nginx on certificate renewal.
5. start nginx



## To Do
* Dry run before generation of certs.
* Support for subdomains
* Support for custom nginx default configuration
