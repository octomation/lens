#!/usr/bin/env bash

echo "script:" $0 "call stack:" $@

REPEAT_LOG=/tmp/repeat.log
SSL_PATH=/etc/nginx/ssl
DHPARAMS=dhparams.pem
DEV_CERT=xip.io.crt
DEV_KEY=xip.io.key
WEBROOT=/usr/share/nginx/html
CONFIG_PATH=/etc/nginx/conf.d
SITES_PATH=/etc/nginx/sites-available

key_name()   { echo "${SSL_PATH}/${fqdn:=$1}_le-key.pem"; }
cert_name()  { echo "${SSL_PATH}/${fqdn:=$1}_le-crt.pem"; }
chain_name() { echo "${SSL_PATH}/${fqdn:=$1}_le-chain-crt.pem"; }

echo "normalizing..."
    [ -n "${LE_ENABLED}" -a -n "${LE_EMAIL}" ]
    LE_ENABLED=$(($? == 0))

    [ -n "${DEV_ENABLED}" ]
    DEV_ENABLED=$(($? == 0))

    HTTPS_ENABLED=$(($LE_ENABLED == 1 || $DEV_ENABLED == 1))

    echo "  environment:"
    echo "    TIME_ZONE:    " $TIME_ZONE
    echo "    LE_ENABLED:   " $LE_ENABLED
    echo "    LE_EMAIL:     " $LE_EMAIL
    echo "    DEV_ENABLED:  " $DEV_ENABLED
    echo "    HTTPS_ENABLED:" $HTTPS_ENABLED
    echo ""
    echo "    REPEAT_LOG:   " $REPEAT_LOG
    echo "    SSL_PATH:     " $SSL_PATH
    echo "    DHPARAMS:     " ${SSL_PATH}/${DHPARAMS}
    echo "    DEV_CERT:     " ${SSL_PATH}/${DEV_CERT}
    echo "    DEV_KEY:      " ${SSL_PATH}/${DEV_KEY}
    echo "    WEBROOT:      " $WEBROOT
    echo "    CONFIG_PATH:  " $CONFIG_PATH
    echo "    SITES_PATH:   " $SITES_PATH
echo "done"

echo "setup timezone..."
    cp /usr/share/zoneinfo/"${TIME_ZONE}" /etc/localtime
    echo "${TIME_ZONE}" > /etc/timezone
echo "done"

echo "copy configurations..."
(
    cd $SITES_PATH
    for site in $(ls); do
        file=$(basename $site .conf)
        conf=${CONFIG_PATH}/${file}.conf
        cp $site $conf
        echo "  ${SITES_PATH}/${site} copied to ${conf}"
    done
)
echo "done"

dhparam() {
    echo "make dhparams..."
    if [ ! -f ${SSL_PATH}/${DHPARAMS} ]; then
        (
            cd $SSL_PATH
            openssl dhparam -out $DHPARAMS 2048
            if [ $? -gt 0 ]; then
                echo "  [CRITICAL] cannot generate Diffie-Hellman parameters"
                echo "done"
                return 1
            fi
            chmod 600 $DHPARAMS
        )
    else
        sleep 5 # give nginx time to start
        echo "  skipped"
    fi
    echo "done"
}

generate() {
    echo "generate self-signed certificate..."
    if [ ! -f ${SSL_PATH}/${DEV_CERT} -o ! -f ${SSL_PATH}/${DEV_KEY} ]; then
        (
            cd $SSL_PATH
            openssl req -out $DEV_CERT -new -newkey rsa -keyout $DEV_KEY -config local.conf -x509 -days 365
            if [ $? -gt 0 ]; then
                echo "  [CRITICAL] cannot generate self-signed certificate"
                echo "done"
                return 1
            fi
            chmod 600 $DEV_CERT $DEV_KEY
            openssl x509 -in $DEV_CERT -text -noout
        )
    else
        echo "  skipped"
    fi
    echo "done"
}

letsencrypt() {
    #     $1                  ${@:2}
    # some.domain
    # some.domain www.some.domain alias.some.domain
    local fqdn=$1
    local aliases=${@:2}
    local domain="-d ${fqdn}"
    for alias in ${aliases[@]}; do
        domain="${domain} -d ${alias}"
    done
    if [ $DEV_ENABLED -eq 1 ]; then
        domain="${domain} --test-cert --dry-run"
    fi
    if [ ${#aliases[@]} -gt 0 ]; then
        echo "run certbot for ${fqdn} with aliases ${aliases}..."
    else
        echo "run certbot for ${fqdn}..."
    fi
    local key=$(key_name $fqdn)
    local certificate=$(cert_name $fqdn)
    local chain=$(chain_name $fqdn)
    echo "  expected key:              " $key
    echo "  expected certificate:      " $certificate
    echo "  expected certificate chain:" $chain
    echo "  -d argument:               " $domain
    mkdir -p ${WEBROOT}/.well-known/acme-challenge
    set -x
    certbot certonly -t -n \
                     --agree-tos \
                     --renew-by-default \
                     --email "${LE_EMAIL}" \
                     --webroot \
                     -w /usr/share/nginx/html \
                     $domain
    local result=$?
    set +x
    if [ $result -gt 0 ]; then return $result; fi
    cp -fv /etc/letsencrypt/live/${fqdn}/privkey.pem   ${key}         || return $?
    cp -fv /etc/letsencrypt/live/${fqdn}/fullchain.pem ${certificate} || return $?
    cp -fv /etc/letsencrypt/live/${fqdn}/chain.pem     ${chain}       || return $?
    echo "done"
}

enable_dev() {
    echo "find all configurations with HTTPS comment..."
    (
        export SSL_KEY=${SSL_PATH}/${DEV_KEY}
        export SSL_CERT=${SSL_PATH}/${DEV_CERT}

        cd $SITES_PATH
        for site in $(grep -l * -e '#:https '); do
            local file=$(basename $site .conf)
            local conf=${CONFIG_PATH}/${file}.conf
            envsubst '${SSL_CERT} ${SSL_KEY}' < $site > $conf
            sed -i "s|#:https ||g" $conf
            sed -i "s|#:dev ||g" $conf
            nginx -t
            if [ $? -gt 0 ]; then
                cat $site > $conf
                echo "  [CRITICAL] configuration ${SITES_PATH}/${site} without HTTPS and DEV comments is invalid"
            else
                echo "  configuration ${conf} is updated"
            fi
        done
    )
    echo "done"
}

enable_prod() {
    #     $1
    # some.domain
    local fqdn=$1
    echo "find configuration file for ${fqdn}..."
    (
        export SSL_KEY=$(key_name $fqdn)
        export SSL_CERT=$(cert_name $fqdn)
        export SSL_CHAIN=$(chain_name $fqdn)

        cd $SITES_PATH
        local site=''
        if [ -f $fqdn ]; then
            site=$fqdn
        elif [ -f ${fqdn}.conf ]; then
            site=${fqdn}.conf
        else
            echo "  [CRITICAL] cannot find neither ${fqdn} nor ${fqdn}.conf in ${SITES_PATH}"
            echo "done"
            return 1
        fi
        local file=$(basename $site .conf)
        local conf=${CONFIG_PATH}/${file}.conf
        envsubst '${SSL_CERT} ${SSL_KEY} ${SSL_CHAIN}' < $site > $conf
        sed -i "s|#:https ||g" $conf
        sed -i "s|#:le ||g" $conf
        nginx -t
        if [ $? -gt 0 ]; then
            cat $site > $conf
            echo "  [CRITICAL] configuration ${SITES_PATH}/${site} without HTTPS and LE comments is invalid"
            echo "done"
            return 1
        else
            echo "  configuration ${conf} is updated"
        fi
    )
    echo "done"
}

process() {
    #      ${@:1}
    # specifications...
    # - where specification is domain:alias,...
    if [ $HTTPS_ENABLED -eq 0 ]; then
        echo "  HTTPS is disabled"
        return 0
    fi
    dhparam || return $?
    if [ $LE_ENABLED -eq 0 ]; then
        echo "  [WARNING] let's encrypt is disabled"
        echo "  [WARNING] environment will be configured for local development"
        generate   || return $?
        enable_dev || return $?
    else
        for spec in $@; do
            local fqdn=$(echo    $spec | awk -F ':' '{print $1}')
            local aliases=$(echo $spec | awk -F ':' '{print $2}' | tr ',' ' ')
            letsencrypt $fqdn $aliases
            if [ $? -gt 0 ]; then
                echo "  [CRITICAL] cannot process ${fqdn} certificate"
            else
                enable_prod $fqdn
                if [ $? -gt 0 ]; then
                    echo "  [CRITICAL] cannot set up configuration for ${fqdn}"
                fi
            fi
        done
    fi
    nginx -s reload
    local result=$?
    if [ $result -gt 0 ]; then
        echo "  [CRITICAL] cannot reload nginx"
    fi
    return $result
}

wrapped_process() {
    echo "start process..."
    process $@
    local result=$?
    echo "done"
    return $result
}

watch() {
    while :
    do
        echo "[TODO] watching to renew..."
        sleep 10d
    done
}

case $1 in
    renew)
        echo "[TODO] force renew..."
        ;;
    repeat)
        if [ ! -f $REPEAT_LOG ]; then
            echo '[CRITICAL] nothing to repeat'
            exit 1
        fi
        wrapped_process $(cat $REPEAT_LOG)
        ;;
    process)
        wrapped_process ${@:2}
        ;;
    *)
        if [ ${#@} -gt 0 ]; then
            echo $@ > $REPEAT_LOG
            echo "${@} copied to ${REPEAT_LOG}"
        fi
        (wrapped_process $@ && watch) &
        echo "start nginx..."
        nginx -g "daemon off;"
        ;;
esac
