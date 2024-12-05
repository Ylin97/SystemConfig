# Get Windows host IP address
function __get_host_ip  
    set  file_path "$HOME/Share/.windows_ip_info"
    set  host_ip (grep -P "@{InterfaceAlias=以太网(?!\s\d);.*}" $file_path | sed -E 's/.*IPv4Address=([0-9.]+).*/\1/') 
  
    if [ -z "$host_ip" ]  
	set host_ip (grep -P "@{InterfaceAlias=WLAN(?!\s\d);.*}" $file_path | sed -E 's/.*IPv4Address=([0-9.]+).*/\1/')
    end  
    echo $host_ip  
end

function __setproxy_http
    set  host_ip (__get_host_ip)

    set -gx https_proxy "$host_ip:$argv[1]"
    set -gx HTTPS_PROXY "$host_ip:$argv[1]"
    set -gx http_proxy "$host_ip:$argv[1]"
    set -gx HTTP_PROXY "$host_ip:$argv[1]"

    # 配置Git代理
    git config --global https.proxy "https://$host_ip:$argv[1]"
    git config --global http.proxy "http://$host_ip:$argv[1]"
end

function __setproxy_socks
    set  host_ip (__get_host_ip)
    set -gx https_proxy socks5://$host_ip:$argv[1]
    set -gx HTTPS_PROXY socks5://$host_ip:$argv[1]
    set -gx http_proxy socks5://$host_ip:$argv[1]
    set -gx HTTP_PROXY socks5://$host_ip:$argv[1]

    git config --global https.proxy socks5://$host_ip:$argv[1]
    git config --global http.proxy socks5://$host_ip:$argv[1]
end

function setproxy
    __setproxy_http $argv[1]
end

function setproxy-c
    __setproxy_http 7890
end

function setproxy-v
    __setproxy_http 10809
end

function setproxy-sc
    __setproxy_socks 7890
end

function setproxy-sv
    __setproxy_socks 10808
end

function unsetproxy
    set -e https_proxy
    set -e HTTPS_PROXY
    set -e http_proxy
    set -e HTTP_PROXY

    git config --global --unset http.proxy
    git config --global --unset https.proxy
end

