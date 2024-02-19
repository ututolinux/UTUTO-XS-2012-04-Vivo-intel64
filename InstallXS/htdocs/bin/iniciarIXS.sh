#!/bin/bash

if [ ! -d /mnt/instalar/admin ]; then
	/bin/rm -f /mnt/instalar
	/bin/ln -sf /mnt/livecd/mnt/cdrom /mnt/instalar
fi
while true;
do
	if [ "$(grep '[0-9]*' <(fbres 2>/dev/null) | wc -l)" = "1" ]; then
		links -g -background-color 0xFFFFFF -foreground-color 0x999999 http://localhost
	else
		links http://localhost
	fi
	if [ -f /tmp/PARTICIONAR ]; then
		cfdisk
		rm /tmp/PARTICIONAR
	else
		exit
	fi
done

