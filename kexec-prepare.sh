#!/bin/env sh
# A script to automate kexec, which allows rebooting without having to go to BIOS
# or do a POST.
# Usage: ./kexec-prepare.sh <kernel-name> <option>
# No option implies to reuse the current command line options.
# The -g option will read the kernel command line options in /etc/default/grub
# and append to it the root filesystem that is currently mounted at '/'
# This script checks to make sure the kernel and initrd exist before issuing
# the command to kexec.
# Copyright 2016 Samantha McVey <samantham@posteo.net>
# Licensed under the GPLv3.
# 
BOOT_DIR="/boot"
LINUX="${1}"
INITRD="${1}"
LINUX_FILE="${BOOT_DIR}/vmlinuz-${LINUX}"
INITRD_FILE="${BOOT_DIR}/initramfs-${INITRD}.img"
if [ -f "${LINUX_FILE}" ]; then
  printf "Found %s\n" "${LINUX_FILE}"
else
  printf "Can't find kernel at %s\n" "${LINUX_FILE}"
  exit 1
fi
if [ -f "${INITRD_FILE}" ]; then
  printf "Found %s\n" "${INITRD_FILE}"
else
  printf "Can't find initrd at %s\n" "${INITRD_FILE}"
  exit 1
fi

if [ "${2}" = "-g" ]; then
  CMD_LINE=$(grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub | sed -e 's/GRUB_CMDLINE_LINUX_DEFAULT=\"//' -e 's/\"$//')
  ROOT=$(mount | grep '/ ' | cut -d ' ' -f 1)
  printf "Command line: %s\n" "$CMD_LINE"
  printf "Root: %s\n" "$ROOT"
  sudo kexec -l "${LINUX_FILE}" --initrd="${INITRD_FILE}" --command-line="root=${ROOT} rw ${CMD_LINE}"
else
  printf "Reusing existing command line\n"
  sudo kexec -l "${LINUX_FILE}" --initrd="${INITRD_FILE}" --reuse-cmdline
fi
