# pritunl-link-docker
# source: https://github.com/red-avtovo/pritunl-link-docker



## Run
```
docker run -d --privileged --network=host -e URL="pritunl://<auth>@<host>" --name link redavtovo/pritunl-link
```

### Requirements

* Privileged container
* Host network

For experiments:
```
docker run -it --rm --privileged --network=host alpine sh
```

Note:
- You need to add routing to the machine with docker this container on your router
