# Private shell policy, sourced by Home Manager; never auto-select on source.
_proxy_export() {
    export http_proxy="$_proxy_http" https_proxy="$_proxy_http"
    export HTTP_PROXY="$_proxy_http" HTTPS_PROXY="$_proxy_http"
    export all_proxy="$_proxy_socks" ALL_PROXY="$_proxy_socks"
    export npm_config_proxy="$_proxy_http" npm_config_https_proxy="$_proxy_http"
    export no_proxy='localhost,127.0.0.1,::1' NO_PROXY='localhost,127.0.0.1,::1'
}

_proxy_select() {
    case "$1" in
        local) _proxy_http="$PROXY_LOCAL_HTTP"; _proxy_socks="$PROXY_LOCAL_SOCKS" ;;
        network) _proxy_http="$PROXY_NETWORK_HTTP"; _proxy_socks="$PROXY_NETWORK_SOCKS" ;;
        *) print -u2 'proxy: choose local or network'; return 1 ;;
    esac
    if [[ -z "$_proxy_http" || -z "$_proxy_socks" ]]; then
        # Port zero cannot be a listening TCP service. Do not leave a fresh
        # required-proxy shell in direct mode after a runtime misconfiguration.
        _proxy_http='http://127.0.0.1:0'; _proxy_socks='socks5://127.0.0.1:0'
        _proxy_export
        print -u2 'proxy: empty endpoints; required selection blocked. Configure youturn.proxy endpoints or explicitly choose proxy off.'
        return 1
    fi
}

proxy() {
    local cmd="${1:-help}" mode="${2:-local}"
    local _proxy_http _proxy_socks
    case "$cmd" in
        on)
            _proxy_select "$mode" || return 1
            # Export BEFORE probing: unavailable required proxies never mean direct.
            _proxy_export
            if ! "$_YOUTURN_PROXY_HELPER" probe "$_proxy_http" "$_proxy_socks"; then
                print -u2 'proxy: required selection retained; check the proxy, run proxy test, or explicitly choose proxy off for direct mode'
                return 1
            fi
            [[ "${3:-}" == --quiet ]] || print "Proxy enabled — $mode"
            ;;
        off)
            unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
            unset npm_config_proxy npm_config_https_proxy no_proxy NO_PROXY
            [[ "${2:-}" == --quiet ]] || print 'Proxy disabled (direct mode).'
            ;;
        show)
            if [[ -n "$http_proxy" ]]; then
                print "HTTP proxy: $http_proxy"
                print "SOCKS proxy: $all_proxy"
                print 'Proxy selected (reachability not implied). Run proxy test.'
            else
                print 'Proxy: disabled (direct mode).'
            fi
            ;;
        test)
            [[ -n "$http_proxy" ]] || { print -u2 'proxy: run proxy on first'; return 1; }
            "$_YOUTURN_PROXY_HELPER" probe "$http_proxy" "$all_proxy" || return 1
            # Explicit user-requested end-to-end check, not startup behavior.
            if curl -sf --max-time 5 --noproxy '' --proxy "$http_proxy" https://www.google.com >/dev/null 2>&1; then
                print 'Connection successful.'
            else
                print -u2 'Connection failed through the selected proxy; selection retained.'
                return 1
            fi
            ;;
        macos-on|macos-off)
            [[ "$OSTYPE" == darwin* ]] || { print -u2 'proxy: macos-on/off require macOS'; return 1; }
            if [[ "$cmd" == macos-on ]]; then
                _proxy_select "$mode" || return 1
                "$_YOUTURN_PROXY_HELPER" system-on "$_proxy_http" "$_proxy_socks" || return 1
                print "macOS system proxy enabled — $mode"
            else
                "$_YOUTURN_PROXY_HELPER" system-off || return 1
                print 'macOS system proxy disabled.'
            fi
            ;;
        *) print 'Usage: proxy on [local|network] | off | show | test | macos-on [local|network] | macos-off' ;;
    esac
}

_proxy_startup() {
    case "$1" in
        off) proxy off --quiet ;;
        local|network) proxy on "$1" --quiet ;;
        *) print -u2 'proxy: invalid configured default'; return 1 ;;
    esac
}
