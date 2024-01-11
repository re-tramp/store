#!/usr/bin/env bash

set -x

XRAY_NAME='app'
CADDY_NAME='caddy'
CLOUDFLARED_NAME='argo'




download() {

    local link="$1"
    local name="$2"

    $(type -P curl) -sSL "$link" -o "$name"

    if [ "$?" != 0 ]; then
        echo "download $name failed !"
        exit 1
    fi
}

verify_system() {

    if [ "`uname`" != 'Linux' ] || [ "`uname -m`" != 'x86_64']; then
        echo "unspport operating system: `uname -a`"
        exit 1
    fi

}


download_app() {
    
    verify

    local enable_argo=${1:-false}
    local enable_caddy=${2:-false}
    local xray_link=''
    local caddy_link=''
    local argo_link=''


    if [ ! -f "$XRAY_NAME" ]; then
        download "$xray_link" "$XRAY_NAME"
    else
        echo "file alread exsit !"
    fi

    if [ "$enable_argo" ] && [ ! -f "$CLOUDFLARED_NAME" ]; then
        download "$argo_link" "$CLOUDFLARED_NAME"
    else
        echo "argo is disabled or exist!"
    fi


    if [ "$enable_caddy" ] && [ ! -f "$CADDY_NAME" ]; then
        download "$caddy_link" "$CADDY_NAME"
    else
        ehco "caddy is disabled or exist!"
    fi

}

generate_config() {

cat > xray.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port": 8880,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "uuid"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/uuid-vm"
                }
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        }
    ]
}
EOF


}
