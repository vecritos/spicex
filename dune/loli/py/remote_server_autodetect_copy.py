#!/usr/bin/env python3
import os
import subprocess
import sys
from pathlib import Path
from paramiko import SSHConfig
import argparse

# Thresholds
RCLONE_THRESHOLD = 500 * 1024 * 1024       # 500 MB → use rclone
CHUNK_THRESHOLD = 5 * 1024 * 1024 * 1024   # 5 GB → split into chunks for rclone

SSH_CONFIG_FILE = Path.home() / ".ssh/config"

def parse_ssh_config():
    """Parse SSH config and return a dictionary of host settings"""
    config = SSHConfig()
    hosts = {}
    if SSH_CONFIG_FILE.exists():
        with open(SSH_CONFIG_FILE) as f:
            config.parse(f)
        for host in config.get_hostnames():
            if host == '*':
                continue
            host_config = config.lookup(host)
            hosts[host] = {
                "hostname": host_config.get("hostname", host),
                "user": host_config.get("user", os.getlogin()),
                "port": int(host_config.get("port", 22)),
            }
    return hosts

def get_size(path):
    """Return total size in bytes for a file/folder"""
    if os.path.isfile(path):
        return os.path.getsize(path)
    total = 0
    for root, dirs, files in os.walk(path):
        for f in files:
            fp = os.path.join(root, f)
            total += os.path.getsize(fp)
    return total

def human_size(size):
    """Convert bytes to human-readable string"""
    for unit in ['B','KB','MB','GB','TB']:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024
    return f"{size:.2f} PB"

def chunk_files(source, chunk_size=CHUNK_THRESHOLD):
    """Yield lists of files that together don't exceed chunk_size"""
    files = []
    for root, dirs, filenames in os.walk(source):
        for f in filenames:
            files.append(os.path.join(root, f))

    chunks = []
    current_chunk = []
    current_size = 0

    for f in files:
        fsize = os.path.getsize(f)
        if fsize > chunk_size:
            # Single file bigger than chunk size → transfer separately
            if current_chunk:
                chunks.append(current_chunk)
                current_chunk = []
                current_size = 0
            chunks.append([f])
        else:
            if current_size + fsize > chunk_size:
                chunks.append(current_chunk)
                current_chunk = [f]
                current_size = fsize
            else:
                current_chunk.append(f)
                current_size += fsize
    if current_chunk:
        chunks.append(current_chunk)
    return chunks

def main():
    parser = argparse.ArgumentParser(description="Copy files to SSH servers using scp or rclone with dry-run info")
    parser.add_argument("--rclone", action="store_true", help="Force using rclone")
    parser.add_argument("--scp", action="store_true", help="Force using scp")
    parser.add_argument("--source", type=str, help="Local source path")
    parser.add_argument("--dest", type=str, help="Remote destination path")
    parser.add_argument("--host", type=str, help="Server alias from SSH config")
    args = parser.parse_args()

    hosts = parse_ssh_config()
    if not hosts:
        print("No SSH hosts found in ~/.ssh/config")
        sys.exit(1)

    # Pick server
    server = args.host
    if not server:
        print("Available servers:")
        for i, h in enumerate(hosts):
            print(f"{i+1}: {h}")
        choice = input("Select server (name or number): ").strip()
        if choice.isdigit():
            choice = int(choice)
            server = list(hosts.keys())[choice-1]
        else:
            server = choice
            if server not in hosts:
                print(f"{server} not found in SSH config")
                sys.exit(1)
    else:
        if server not in hosts:
            print(f"{server} not found in SSH config")
            sys.exit(1)

    host_info = hosts[server]

    # Source and destination
    source = args.source or input("Enter local source path: ").strip()
    destination = args.dest or input("Enter remote destination path: ").strip()

    size_bytes = get_size(source)
    size_str = human_size(size_bytes)

    # Decide which method
    if args.rclone:
        method = "rclone"
    elif args.scp:
        method = "scp"
    else:
        method = "rclone" if size_bytes > RCLONE_THRESHOLD else "scp"

    print(f"\n--- Dry Run ---")
    print(f"Using {method} to copy {size_str} from {source} to {destination} using {host_info['user']}@{host_info['hostname']}\n")

    confirm = input("Proceed with transfer? (y/n): ").strip().lower()
    if confirm != 'y':
        print("Aborted.")
        sys.exit(0)

    # Execute transfer
    if method == "scp":
        port_option = f"-P {host_info['port']}" if host_info['port'] != 22 else ""
        cmd = f"scp -r {port_option} '{source}' {host_info['user']}@{host_info['hostname']}:'{destination}'"
        print(f"Executing: {cmd}\n")
        subprocess.run(cmd, shell=True)
    else:
        # rclone chunking logic for very large transfers
        if size_bytes > CHUNK_THRESHOLD:
            print(f"Chunking large file(s) > {human_size(CHUNK_THRESHOLD)} for transfer...")
            chunks = chunk_files(source)
            for i, chunk in enumerate(chunks):
                chunk_path_str = ' '.join([f"'{f}'" for f in chunk])
                print(f"Transferring chunk {i+1}/{len(chunks)} ({len(chunk)} files)...")
                cmd = f"rclone copy {chunk_path_str} '{server}:{destination}' --progress"
                subprocess.run(cmd, shell=True)
        else:
            cmd = f"rclone copy '{source}' '{server}:{destination}' --progress"
            print(f"Executing: {cmd}\n")
            subprocess.run(cmd, shell=True)

if __name__ == "__main__":
    main()
