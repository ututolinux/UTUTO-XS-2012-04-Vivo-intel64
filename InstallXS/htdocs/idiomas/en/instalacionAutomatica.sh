#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

LANG_FULLDISK=" Full disk"
LANG_PARTITION="Partition"
LANG_ACTUALPARTITION="Current partition"
LANG_FREESPACE="Free space"
LANG_INSTALL="Install >>"

LANG_ASK4CONFIRMATION="You selected the following:
<p>
<br>&nbsp;Languaje: <b>$IDIOMA</b>
<br>&nbsp;City: <b>${ZONAHORARIA//__//}</b>
<br>&nbsp;Profile: <b>$(nombre="NOMBRE_$STAGEAINSTALAR"; echo ${!nombre})</b>
<br>&nbsp;Partition: <b>/dev/$PARTICIONROOT</b>
<br>	
</p>
Press <small><b>Install</b></small> to install UTUTO XS"

LANG_REBOOTING="Rebooting the system...<br><br>If the system does not restart, reboot it manually."

LANG_PARTITION2SMALL="Error seleccting destination partition. [$PARTICIONROOT] is not valid, choose another partition."
