#version: 1.0
#!/usr/bin/env bash
set -e

remove() {
    export PATH=$PATH:$HOME/gaianet/bin/
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":4, "latest_step":1, "all_step":3, "messages":"service stop"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":4, "latest_step":2, "all_step":3, "messages":"service remove"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":3, "latest_step":3, "all_step":3, "messages":"node remove"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo "[+] 3Done9" > /tmp/gaianet_output.txt
}

install(){
    export PATH=$PATH:$HOME/gaianet/bin/
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":2, "latest_step":1, "all_step":4, "messages":"script download"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":2, "latest_step":2, "all_step":4, "messages":"gaianet init"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":2, "latest_step":3, "all_step":4, "messages":"gaigaianet start"}}}' > /tmp/gaianet_output.txt
    sleep 4
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":1, "latest_step":4, "all_step":4, "messages":"gaianet node successfully"}}}' > /tmp/gaianet_output.txt
    sleep 4

    nohup gaianet info | tee /tmp/gaianet_output.txt > /dev/null 2>&1 & 
    while ! tail -n1 /tmp/gaianet_output.txt | grep -q "[+] 3Done9"; do
        sleep 2  # 2초마다 확인
        if ! pgrep -f "gaianet info" > /dev/null; then
            echo "[+] 3Done9" >> /tmp/gaianet_output.txt
            break
        fi
    done
    echo "gaianet||" >> /root/node/installed/node_list.enc
    sleep 4
}

restart(){
    export PATH=$PATH:$HOME/gaianet/bin/
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":6, "latest_step":1, "all_step":1, "messages":"node restart"}}}'
    sleep 4
    echo "[+] 3Done9" > /tmp/gaianet_output.txt
}

stop(){
    export PATH=$PATH:$HOME/gaianet/bin/
    echo '{"IP":"1.1.1.1", "Nodes":{"gainanet":{"status":5, "latest_step":1, "all_step":1, "messages":"node stop"}}}'
    sleep 4
    echo "[+] 3Done9" > /tmp/gaianet_output.txt
}

case "$1" in
    install)
        install
        ;;
    remove)
	    remove
        ;;
    restart)
        restart
        ;;
    stop)
        stop
        ;;
esac
