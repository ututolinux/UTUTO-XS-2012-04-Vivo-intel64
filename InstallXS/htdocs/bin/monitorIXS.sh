#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

cd $(dirname $0)

while true
do
	if [ -f /tmp/datosdeinstalacion ]; then
		. /tmp/datosdeinstalacion
		cd $DIRBASE/modulos/$MODULOACTUAL/
		sh $DIRBASE/modulos/$MODULOACTUAL/instalar.sh 2>&1 | tee -a -i /var/log/installxs.log
		rm -f /tmp/datosdeinstalacion
	fi
	sleep 1
	if [ -f /tmp/reiniciar ]; then
		rm -f /tmp/reiniciar
		reboot
	fi
	sleep 1
done
