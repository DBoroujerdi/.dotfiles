localip() {
    ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}'
}

whoport() {
    lsof -t -i :$1 -sTCP:LISTEN
}

killport() {
    local pid=$(whoport $1)
    if [[ -n $pid ]]; then
        kill -9 $pid
    else
        echo "No process found on port $1"
    fi
}
