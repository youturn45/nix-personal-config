"""Private shared proxy mechanics; never silently fall back to direct traffic."""
import argparse
import ipaddress
import queue
import re
import socket
import subprocess
import sys
import threading
from urllib.parse import urlsplit


class ProxyError(Exception):
    pass


def endpoint(url):
    """Validate without ever including credentials/input in errors."""
    try:
        parsed = urlsplit(url)
        host, port = parsed.hostname, parsed.port
        if (parsed.scheme not in ('http', 'https', 'socks5', 'socks5h')
                or not host or not port or not 1 <= port <= 65535
                or parsed.path not in ('', '/') or parsed.query or parsed.fragment
                or any(c.isspace() or ord(c) < 32 for c in url)):
            raise ValueError()
        if ':' in host:
            ipaddress.IPv6Address(host)
        else:
            labels = host.rstrip('.').split('.')
            if len(host) > 253 or any(not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?', label) for label in labels):
                raise ValueError()
            if re.fullmatch(r'[0-9.]+', host):
                ipaddress.IPv4Address(host)
        return host, port
    except (ValueError, TypeError):
        raise ProxyError('Invalid proxy URL; use http(s)://host:port or socks5://host:port') from None


def probe_proxy(url, timeout=2.0, connect=None):
    """Bound the entire TCP check (including DNS); no HTTP/model request."""
    host, port = endpoint(url)
    results = queue.Queue()
    connect = connect or socket.create_connection
    def check():
        try:
            with connect((host, port), timeout=timeout):
                pass
            results.put(True)
        except OSError:
            results.put(False)
    threading.Thread(target=check, daemon=True).start()
    try:
        reachable = results.get(timeout=timeout)
    except queue.Empty:
        reachable = False
    if not reachable:
        raise ProxyError('Selected proxy is unreachable; start/check the proxy service or select off explicitly for direct mode. Proxy selection was not cleared.')


def configure_system(mode, http=None, socks=None, *, run=subprocess.run,
                     executable='/usr/sbin/networksetup'):
    """Apply settings without TCP precheck: the daemon engine starts AFTER this."""
    if mode not in ('on', 'off'):
        raise ProxyError('System proxy mode must be on or off')
    if mode == 'on':
        http_host, http_port = endpoint(http)
        socks_host, socks_port = endpoint(socks)
        http_url, socks_url = urlsplit(http), urlsplit(socks)
        if (http_url.scheme != 'http' or socks_url.scheme != 'socks5'
                or any(value is not None for value in (
                    http_url.username, http_url.password, socks_url.username, socks_url.password))):
            raise ProxyError('macOS system proxies require unauthenticated http:// and socks5:// endpoints; unsupported URL semantics were not applied')
    failures = 0
    def command(action, *args):
        nonlocal failures
        try:
            result = run([executable, action, *args], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                return result
        except (OSError, subprocess.TimeoutExpired):
            pass
        failures += 1
        service = args[0] if args else 'service enumeration'
        print(f'proxy: {service}: {action} failed; check permissions and network service settings', file=sys.stderr)
        return None
    result = command('-listallnetworkservices')
    if result is not None:
        for line in result.stdout.splitlines()[1:]:
            service = line.strip()
            # Asterisk lines are disabled services, not names to pass to setters.
            if not service or service.startswith('*') or re.search('tailscale|bridge|jtag|bluetooth|vpn', service, re.I):
                continue
            if mode == 'on':
                command('-setwebproxy', service, http_host, str(http_port))
                command('-setsecurewebproxy', service, http_host, str(http_port))
                command('-setsocksfirewallproxy', service, socks_host, str(socks_port))
                command('-setwebproxystate', service, 'on')
                command('-setsecurewebproxystate', service, 'on')
                command('-setsocksfirewallproxystate', service, 'on')
                # No RFC1918 bypass: keep LAN routing under Mihomo policy.
                command('-setproxybypassdomains', service, '127.0.0.1', 'localhost', '::1', '*.local', '169.254/16')
            else:
                for action in ('-setwebproxystate', '-setsecurewebproxystate', '-setsocksfirewallproxystate'):
                    command(action, service, 'off')
    if failures:
        print(f'proxy: {failures} action(s) failed; settings may be partially applied; no success claimed', file=sys.stderr)
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['probe', 'system-on', 'system-off'])
    parser.add_argument('http', nargs='?')
    parser.add_argument('socks', nargs='?')
    args = parser.parse_args()
    try:
        if args.action == 'probe':
            probe_proxy(args.http)
            if args.socks:
                probe_proxy(args.socks)
            return 0
        return configure_system('on' if args.action == 'system-on' else 'off', args.http, args.socks)
    except ProxyError as err:
        print(f'proxy: {err}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
