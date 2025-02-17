#!/bin/bash
create_directory() {
    mkdir /root/node
    mkdir /root/node/enc
    mkdir /root/node/installed
    touch /root/node/installed/node_list.enc
    mkdir /root/node/script/
    mkdir /root/node/script/health_check
    mkdir /root/node/script/nodes
}

create_enc() {
    cd /root/node/enc
    echo "$1" > aes
    if ! command -v openssl &> /dev/null; then
        . /etc/os-release
        case "$VERSION_ID" in
            "20.04"|"22.04"|"23.10")
                sudo apt update && sudo apt install -y openssl
                ;;
            "18.04")
                sudo apt update && sudo apt install -y openssl
                ;;
            "16.04")
                sudo apt update && sudo apt install -y openssl
                ;;
            *)
                echo "[-] Not support"
                exit 1
                ;;
        esac
    fi

    if [ ! -f private.pem ] || [ ! -f public.pem ]; then
        openssl genpkey -algorithm RSA -out private.pem
        openssl rsa -in private.pem -pubout -out public.pem
    else
        echo "[-] Already"
    fi

    read -p "[*] Input Password: " user_input

    echo -n "$user_input" > plaintext.txt

    openssl rsautl -encrypt -pubin -inkey public.pem -in plaintext.txt -out encrypted.bin
    rm -rf /root/node/enc/plaintext.txt
    
    base64 encrypted.bin > encrypted.b64
    
}

create_agent() {
    cd /root/node
    major_version=$(cat /etc/issue | grep -oP 'Ubuntu \K[0-9]+')
    wget https://github.com/sweet39352/Node/raw/refs/heads/main/agents/$major_version/agent -P /root/node
    chmod 777 /root/node/agent
}

create_service() {
    cat <<EOF > /etc/systemd/system/node-agent.service
[Unit]
Description=Node Agent Service
After=network.target

[Service]
ExecStart=/root/node/agent
Restart=always
User=root
WorkingDirectory=/root/node
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node-agent

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable node-agent.service
    systemctl start node-agent.service
    echo "[*] Node Agent 서비스가 등록되고 시작되었습니다."
}

remove_service() {
    if systemctl list-units --type=service | grep -q "node-agent"; then
        systemctl stop node-agent.service
        systemctl disable node-agent.service
        rm /etc/systemd/system/node-agent.service
        systemctl daemon-reload
        echo "[*] Node Agent 서비스가 종료되고 제거되었습니다."
        pkill agent
    else
        echo "[-] Node Agent 서비스가 존재하지 않습니다."
    fi
}



print_agent_id(){
    echo ""
    echo ""
    echo ""
    echo "==================================="
    echo ""
    echo "Agent ID: "
    cat enc/encrypted.b64 | tr -d '\n'
    echo ""
    echo "==================================="
}

#remove_service
create_directory
create_enc $1
create_agent
create_service
print_agent_id
