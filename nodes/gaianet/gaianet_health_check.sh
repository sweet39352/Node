#version: 1.0
#!/bin/bash
if [ -f /etc/issue ]; then
    UBUNTU_VERSION=$(cat /etc/issue | sed 's/\\[a-z]//g')
fi
install_check() {
    local ip="1.1.1.1"  # 기본 IP 설정 (필요시 인자로 받을 수 있음)
    
    # frpc와 gaias 프로세스 확인
    if [ "$(pidof frpc gaias | wc -w)" -eq 2 ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":1, "latest_step":4, "all_step":4, "messages":"installed"}}}'
        return 0
    fi
    
    if [ "$(pidof frpc gaias | wc -w)" -ne 2 ] && [ -d "/root/gaianet/" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":5, "latest_step":4, "all_step":4, "messages":"stopped"}}}'
        return 0
    fi
    
    # gaias_install.sh 실행 여부 확인
    local gaianet_install_pid=$(pgrep -f "management.sh")
    
    if [ -n "$gaianet_install_pid" ]; then
        if [ -f /tmp/gaianet_output.txt ]; then
            local output=$(cat /tmp/gaianet_output.txt)
            local latest_step=$(echo "$output" | grep -o '"latest_step": [0-9]*' | awk '{print $2}')
            local all_step=$(echo "$output" | grep -o '"all_step": *[0-9]*' | awk -F': ' '{print $2}')
            local messages=$(echo "$output" | grep -o '"messages": *"[^"]*"' | awk -F'"' '{print $4}')
            
            # [+] 3Done9 문자열 포함 여부 확인
            if echo "$output" | grep -q "\[+\] 3Done9"; then
                local status=1
            else
                local status=2  # 에러 상태로 변경
            fi
            
            echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":'$status', "latest_step":'$latest_step', "all_step":'$all_step', "messages":"'$messages'"}}}'
        fi
    else
        if [ -f /tmp/gaianet_output.txt ]; then
            local output=$(cat /tmp/gaianet_output.txt)
            
            # [+] 3Done9 문자열 포함 여부 확인
            if echo "$output" | grep -q "\[+\] 3Done9"; then
                echo "$output"
            else
                local latest_step=$(echo "$output" | grep -o '"latest_step": [0-9]*' | awk '{print $2}')
                local all_step=$(echo "$output" | grep -o '"all_step": *[0-9]*' | awk -F': ' '{print $2}')
                local messages=$(echo "$output" | grep -o '"messages": *"[^"]*"' | awk -F'"' '{print $4}')
                
                echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":install -1, "latest_step":'$latest_step', "all_step":'$all_step', "messages":"'$messages'"}}}'
            fi
        else
            echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":0, "latest_step":0, "all_step":0, "messages":"not action install"}}}'
        fi
    fi
}

remove_check() {
    local ip="1.1.1.1"  # 기본 IP 설정 (필요시 인자로 받을 수 있음)
    
    # frpc와 gaias 프로세스 확인
    if [ "$(pidof frpc gaias | wc -w)" -eq 0 ] && [ ! -d "/root/gaianet/" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":5, "latest_step":3, "all_step":3, "messages":"gaianet remove"}}}'
        return 0
    fi
    
    # gaianet_remove.sh 실행 여부 확인
    local gaianet_remove_pid=$(pgrep -f "management.sh")
    
    if [ -n "$gaianet_remove_pid" ]; then
        if [ -f /tmp/gaianet_output.txt ]; then
            local output=$(cat /tmp/gaianet_output.txt)
            local latest_step=$(echo "$output" | grep -o '"latest_step": [0-9]*' | awk '{print $2}')
            local all_step=$(echo "$output" | grep -o '"all_step": *[0-9]*' | awk -F': ' '{print $2}')
            local messages=$(echo "$output" | grep -o '"messages": *"[^"]*"' | awk -F'"' '{print $4}')
            
            # [+] 3Done9 문자열 포함 여부 확인
            if echo "$output" | grep -q "\[+\] 3Done9"; then
                local status=3
            else
                local status=4
            fi
            
            echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":'$status', "latest_step":'$latest_step', "all_step":'$all_step', "messages":"'$messages'"}}}'
        fi
    else
        if [ -f /tmp/gaianet_output.txt ]; then
            local output=$(cat /tmp/gaianet_output.txt)
            
            # [+] 3Done9 문자열 포함 여부 확인
            if echo "$output" | grep -q "\[+\] 3Done9"; then
                echo "$output"
            else
                local latest_step=$(echo "$output" | grep -o '"latest_step": [0-9]*' | awk '{print $2}')
                local all_step=$(echo "$output" | grep -o '"all_step": *[0-9]*' | awk -F': ' '{print $2}')
                local messages=$(echo "$output" | grep -o '"messages": *"[^"]*"' | awk -F'"' '{print $4}')
                
                echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":-1, "latest_step":'$latest_step', "all_step":'$all_step', "messages":"'$messages'"}}}'
            fi
        else
            echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":0, "latest_step":0, "all_step":0, "messages":"not action remove"}}}'
        fi
    fi
}

stop_check() {
    #stop
    if [ "$(pidof frpc gaias | wc -w)" -ne 2 ] && [ -d "/root/gaianet/" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":5, "latest_step":4, "all_step":4, "messages":"stopped"}}}'
        return 0
    fi
}

restart_check() {    
    #restart
    local gaianet_restart_pid=$(pgrep -f "management.sh")
    if [ -n "$gaianet_install_pid" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":6, "latest_step":4, "all_step":4, "messages":"restarting"}}}'
        return 0
    fi
}

all_health_check() {
    local ip="1.1.1.1"  # 기본 IP 설정 (필요시 인자로 받을 수 있음)
    local script_status="$2"

    # frpc와 gaias 프로세스 확인
    if [ "$(pidof frpc gaias | wc -w)" -eq 2 ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":1, "latest_step":4, "all_step":4, "messages":"gaianet running"}}}'
        return 0
    fi
    
    if [ "$(pidof frpc gaias | wc -w)" -ne 2 ] && [ -d "/root/gaianet/" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":5, "latest_step":4, "all_step":4, "messages":"stopped"}}}'
        return 0
    fi

    # frpc와 gaias 프로세스 확인
    if [ "$(pidof frpc gaias | wc -w)" -eq 0 ] && [ ! -d "/root/gaianet/" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":0, "latest_step":3, "all_step":3, "messages":"not installed"}}}'
        return 0
    fi

    if [ "$script_status" = "install" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":2, "latest_step":4, "all_step":4, "messages":"installing"}}}'
        return 0
    fi

    if [ "$script_status" = "remove" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":4, "latest_step":4, "all_step":4, "messages":"removing"}}}'
        return 0
    fi

    if [ "$script_status" = "stop" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":6, "latest_step":4, "all_step":4, "messages":"stopping"}}}'
        return 0
    fi

    if [ "$script_status" = "restart" ]; then
        echo '{"IP":"'$ip'", "OS": "'$UBUNTU_VERSION'", "Nodes":{"gaianet":{"status":8, "latest_step":4, "all_step":4, "messages":"restarting"}}}'
        return 0
    fi

}



case "$1" in
    install)
        install_check
        ;;
    remove)
	    remove_check
        ;;
    stop)
        stop_check
        ;;
    restart)
	    restart_check
        ;;
    all_health_check)
        all_health_check $2
        ;;
    *)
        echo "Usage: $0 {install|remove|*}"
        exit 1
        ;;
esac
