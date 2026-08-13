#!/bin/bash
# powershell -> fsutil file createnew C:\wsl-luks.img x*1024^3 (GB)

sudo losetup -fP /mnt/c/wsl-luks.img

losetup -a

sudo cryptsetup luksFormat /dev/loop0
sudo cryptsetup open /dev/loop0 luksdisk
sudo mkfs.ext4 /dev/mapper/luksdisk

sudo mkdir /mnt/luks
sudo mount /dev/mapper/luksdisk /mnt/luks

echo "hello world" | sudo tee /mnt/luks/hello.txt

sudo umount /mnt/luks

sudo cryptsetup close luksdisk

sudo losetup -d /dev/loop0 

LOOP=$(sudo losetup -f --show /mnt/c/wsl-luks.img)

