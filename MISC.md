## Misc (mostly for me right now)
#### Dev SSL

Note that you need to specify full xip host (multi-level wildcards are not allowed)

```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ~/dev/free-roam/bin/fr-dev.key -out ~/dev/free-roam/bin/fr-dev.crt -reqexts v3_req -extensions v3_ca
```
```
Generating a 4096 bit RSA private key
...............................................................................................................................++
......................................++
writing new private key to '/home/austin/dev/free-roam/bin/fr-dev.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:California
Locality Name (eg, city) []:San Francisco
Organization Name (eg, company) [Internet Widgits Pty Ltd]:FreeRoam LLC
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:192.168.0.109.xip.io
Email Address []:austin@freeroam.app
```

http://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate

For Android:
```
sudo openssl x509 -in ~/dev/free-roam/bin/fr-dev.crt -outform der -out ~/dev/free-roam/bin/fr-dev.der.crt
```

Copy free-roam.der.crt to your phone, settings -> security -> install from storage -> select key

`USE_HTTPS=1 npm run dev`
