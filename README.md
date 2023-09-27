# CONTAINERIZED DNIE

## Introduction

This repository contains a containerized version of the set-up
required to use the Spanish DNIE (Electronic Identy Card - eID). It
also fixes some quirks in the postinst scripts of their pkcs11
driver (pkcs11-dnie) that require a working X environment and
a web browser to actually install the package...

More information about the Spanish DNIE can be found here:
[https://www.dnielectronico.es/PortalDNIe](https://www.dnielectronico.es/PortalDNIe/)

Still, the set-up is a bit clunky. Use at your own risk.

## License and disclaimer

Copyright 2023 E. Artiaga

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

## Requirements

You need the pkcs11 driver for Spanish eID, which is not included in this repo.
You can download the Debian version from the following url (at the time of
this writing, they had a version for Debian 11) and validate the check sum:

* [https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_1112](https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_1112)

You need to place the downloaded `libpkcs11-dnie_x.y.z_amd64.deb` package ins
the root of the repo before building the docker image.

Of course, you also need a physical Smart Card reader in your host computer.
The `pcscd` service should be installed and running in your host system for
the container to be able to use your smart cards.

## Details and known issues

The container tries to auto-configure automatically the CA root certificate
and the security device (the smart card reader) for both installed browsers
(chromium and firefox), so it should not be necessary to follow the original
package instructions to configure them manually.

In the case of chromium, the configuration must be done locally in the user
environment. The configuration is checked and updated as part of the container
command script (`launch`):

```bash
if [ ! -e "$HOME/.pki/nssdb" ]; then
    mkdir -p "$HOME/.pki/nssdb"
    chmod 700 "$HOME/.pki/nssdb"
    modutil -force -create -dbdir "$HOME/.pki/nssdb/"
fi
modutil -force -dbdir .pki/nssdb/ -add "DNIe" -libfile "/usr/lib/libpkcs11-dnie.so"
certutil -d "sql:$HOME/.pki/nssdb" -A -t "CT,C,C" -n "AC_RAIZ_DNIE_2" -i "/usr/share/libpkcs11-dnie/AC RAIZ DNIE 2.crt"
```

In the case of firefox, the configuration is done via the included
`policies.json` file:

```json
{
  "policies": {
    ...
    "Certificates": {
      "ImportEnterpriseRoots": true,
      "Install": [
        "/usr/local/share/ca-certificates/AC_RAIZ_DNIE_2.crt"
      ]
    },
    "SecurityDevices": {
      "Add": {
        "DNIe PKCS#11 Module": "/usr/lib/libpkcs11-dnie.so"
      }
    }
    ...
  }
}
```

This file is copied into the `/usr/lib/firefox/distribution` directory, so
it is automatically fetched by firefox when started by any user. You may find
additional attributes to set up via the policies file in the following url:

* [https://github.com/mozilla/policy-templates#securitydevices](https://github.com/mozilla/policy-templates#securitydevices)

### Known issues

Though the configuration seems to be correct when checking the settings
from both chromium and firefox, firefox still appears to have issues when
using the certificates from the smart card to authenticate to certain sites.
For this reason, chromium is currently set as the default browser when
starting the container.

Note that running the browsers in incognito mode seems to interfere
with the security devices. Certain security settings may also limit
the functionality.

Also beware of extensions: they may cause certificate-based authentication
to fail in certain sites.

Finally, the `opensc` and `opensc-pkcs11` packages, though useful for
debugging, may also interfere with the DNIe driver. In particular, if
you have `opensc-pkcs11` installed, then you may have to manually disable
the configured pkcs11 driver module in your browser.

## Building the image

You may tune the `compose.yml` file to your likings. Make sure that
`DNIE_VERSION` matches the version of the dowloaded pkcs11 driver and set
the `DNIE_SUDO` argument to `true` if you want to enable `sudo` in the
container for debugging purposes.

Then, build the image using

```bash
docker compose build
```

If you are using the older stand-alone docker-compose command, then you may
have to run the following:

```bash
docker-compose -f compose.yaml build
```

## Running the container

To run the container, just execute the following command:

```bash
docker compose run --rm dnie
```

A `chromium` window should appear with instructions on how to finish the
pkcs11 driver configuration.

If you prefer using firefox instead of chromium, then you may run:

```bash
docker compose run --rm dnie -c "/launch firefox"
```

You may also start the container with a shell for debugging purposes:

```bash
docker compose run --rm dni -c "/bin/bash -l"
```

## Running without container

If you think having a container for this is overkill (which may be), you
can also install the pkcs11 driver in your host system and run chromium or
firefox from there. But starting a web browser during `dpkg -i` annoys you,
you can use the `dnie_headless` script from this very same repo. Running:

```bash
dnie_headless libpcks11-dnie_x.y.z_amd64.deb
```

will generate a `libpkcs11-dnie-headless_x.y.z+local1_amd64.deb` package
that will not try to start a browser while you are installing it. After
installing the `libpkcs11-dnie-headless_x.y.z+local1_amd64.deb` package,
you can still display the original instructions by running:

```bash
chromium /usr/share/libpkcs11-dnie/launch.html
```

or

```bash
firefox /usr/share/libpkcs11-dnie/launch.html
```

## Validation

The following page contains links to Validation Authorities to check if
the setup is working properly:

* [https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_320&id_menu=15](https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_320&id_menu=15)

## Acknowledgements and references

The following blog contains useful information about configuring the
DNIE for linux:

* [https://aprendolinux.com/instalar-dni-electronico-linux/](https://aprendolinux.com/instalar-dni-electronico-linux/)

The pkcs11 drivers are available in this portal:

* [https://www.dnielectronico.es/PortalDNIe/](https://www.dnielectronico.es/PortalDNIe/)

Useful information about how to configure security devices for linux browsers
can be found here:

* [https://linuxkamarada.com/en/2019/09/26/setting-up-smart-card-authentication-on-google-chrome-chromium/](https://linuxkamarada.com/en/2019/09/26/setting-up-smart-card-authentication-on-google-chrome-chromium/)
