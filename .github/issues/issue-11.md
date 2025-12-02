---
id: 11
database_id: 526186922
node_id: MDU6SXNzdWU1MjYxODY5MjI=
status: closed
title: "entrypoint.sh has invalid logic"
labels: ["help wanted","type:bug"]
url: https://github.com/octomation/lens/issues/11
created_at: 2019-11-20T20:38:16Z
updated_at: 2020-03-28T08:37:21Z
---

# entrypoint.sh has invalid logic

```
Strip directory path and .SUFFIX from FILE
/entrypoint.sh: line 194: ${site}: ambiguous redirect
sed: /etc/nginx/conf.d/.conf: No such file or directory
sed: /etc/nginx/conf.d/.conf: No such file or directory
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
  configuration /etc/nginx/conf.d/.conf is updated
done
2019/11/20 20:37:08 [notice] 51#51: signal process started
```
