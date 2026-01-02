#!/usr/bin/env python3
"""Deploy Flutter patient app to connected phone."""

import subprocess
import sys
import socket
import requests

# ANSI color codes
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
RESET = "\033[0m"

RAILWAY_HEALTH_URL = "https://birth-journal-backend-production.up.railway.app/api/v1/health"
RAILWAY_API_URL = "https://birth-journal-backend-production.up.railway.app/api/v1"


def get_local_wifi_ip():
    """Get the local WiFi IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip if ip and not ip.startswith("127.") else None
    except Exception:
        return None


def check_railway_available():
    """Check if Railway backend is available."""
    try:
        response = requests.get(RAILWAY_HEALTH_URL, timeout=5, verify=False)
        return response.status_code == 200
    except Exception:
        return False


def main():
    print(f"{CYAN}Checking Railway backend availability...{RESET}")

    use_railway = check_railway_available()

    if use_railway:
        print(f"{GREEN}✓ Railway backend is available{RESET}")
        api_url = RAILWAY_API_URL
    else:
        print(f"{YELLOW}✗ Railway backend is not reachable{RESET}")
        local_ip = get_local_wifi_ip()

        if not local_ip:
            print(f"{RED}Error: Could not determine local WiFi IP address{RESET}")
            sys.exit(1)

        api_url = f"http://{local_ip}:8000/api/v1"
        print(f"{YELLOW}Using local WiFi IP: {local_ip}{RESET}")

    print(f"\n{CYAN}============================================{RESET}")
    print(f"{CYAN}  Deploying Polozne Patient App{RESET}")
    print(f"{CYAN}============================================{RESET}")
    print()
    print(f"Backend API: {YELLOW}{api_url}{RESET}")
    print()

    # Check for connected devices
    print(f"{CYAN}Checking for connected devices...{RESET}")
    try:
        subprocess.run("flutter devices", shell=True, check=True)
    except subprocess.CalledProcessError:
        print(f"{RED}Error checking devices{RESET}")
        sys.exit(1)

    print()
    confirmation = input("Proceed with deployment? (y/n): ").strip().lower()
    if confirmation != "y":
        print(f"{YELLOW}Deployment cancelled.{RESET}")
        sys.exit(0)

    print(f"\n{GREEN}Building and deploying app...{RESET}")
    try:
        subprocess.run(
            f"flutter run --dart-define API_BASE_URL={api_url}",
            shell=True,
            check=True,
        )
        print(f"\n{GREEN}[OK] Deployment complete!{RESET}")
    except subprocess.CalledProcessError as e:
        print(f"{RED}Error during deployment: {e}{RESET}")
        sys.exit(1)


if __name__ == "__main__":
    main()
