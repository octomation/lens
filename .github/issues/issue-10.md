---
id: 10
database_id: 525106595
node_id: MDU6SXNzdWU1MjUxMDY1OTU=
status: closed
title: "ACMEv1 is disabled"
labels: ["help wanted","type:critical"]
url: https://github.com/octomation/lens/issues/10
created_at: 2019-11-19T16:06:32Z
updated_at: 2020-03-28T08:37:21Z
---

# ACMEv1 is disabled

```
run certbot for ... with aliases ...
  expected key:               /etc/nginx/ssl/..._le-key.pem
  expected certificate:       /etc/nginx/ssl/..._le-crt.pem
  expected certificate chain: /etc/nginx/ssl/..._le-chain-crt.pem
  -d argument:                -d ...
+ certbot certonly -t -n --agree-tos --renew-by-default --email ... --webroot -w /usr/share/nginx/html -d ...
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator webroot, Installer None
An unexpected error occurred:
The client lacks sufficient authorization :: Account creation on ACMEv1 is disabled. Please upgrade your ACME client to a version that supports ACMEv2 / RFC 8555. See https://community.letsencrypt.org/t/end-of-life-plan-for-acmev1/88430 for details.
Please see the logfiles in /var/log/letsencrypt for more details.
+ local result=1
+ set +x
  [CRITICAL] cannot process ... certificate
2019/11/17 20:40:32 [notice] 33#33: signal process started
```
