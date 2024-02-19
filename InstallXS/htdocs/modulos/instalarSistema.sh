#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

MODULO="instalarSistema"

function instalarSistema() {
	nohup sh $DIRBASE/bin/instalar.sh &
}

case $SIGUIENTEPASO in
	*)
		instalarSistema
	;;
esac


