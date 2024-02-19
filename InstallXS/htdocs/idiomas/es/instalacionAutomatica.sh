#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

LANG_FULLDISK=" Disco completo"
LANG_PARTITION="Particion"
LANG_ACTUALPARTITION="Particion existente"
LANG_FREESPACE="Espacio libre"
LANG_INSTALL="Instalar >>"

LANG_ASK4CONFIRMATION="Usted seleccionó las siguientes opciones:
<p>
<br>&nbsp;Idioma: <b>$IDIOMA</b>
<br>&nbsp;Ciudad: <b>${ZONAHORARIA//__//}</b>
<br>&nbsp;Perfil: <b>$(nombre="NOMBRE_$STAGEAINSTALAR"; echo ${!nombre})</b>
<br>&nbsp;Partición: <b>/dev/$PARTICIONROOT</b>
<br>	
</p>
Presione <small><b>Instalar</b></small> para instalar UTUTO XS"

LANG_REBOOTING="Reiniciando el sistema...<br><br>Si el sistema no reinicia automaticamente en 30 segundos, reinicielo manualmente."

LANG_PARTITION2SMALL="Error al seleccionar la partición del disco donde se instalará el sistema. [$PARTICIONROOT] no es válido, seleccione una partición o un disco."
