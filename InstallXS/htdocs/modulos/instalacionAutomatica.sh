#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $


MODULO="instalacionAutomatica"
# echo "$MODULO" 1>&2


function verificarTamanioDestino() {
	local nombre
	local -i gigas
	local -i kbytes
	local disco=$1
	
	kbytes=$($DIRBASE/bin/runasroot.sh "/sbin/sfdisk -s /dev/$disco")
	gigas=$(( $kbytes / 1024 / 1024 ))
	if [ $gigas -gt 4 ]; then
		echo $gigas
	else
		echo 0
	fi
}

function listarParticionesAuto() {
	local opciones
	local disco
	local particion
	local nombre
	local tamanio=0
	
	$DIRBASE/bin/runasroot.sh "/sbin/sfdisk -s" | grep '^/dev/' | sed "s/^\/dev\///g" > $DIRTMP/discos.txt
	while read disco
	do 
		nombre=${disco//:*/}
		opcion="<label><input type='radio' name='PARTICIONROOT' value=\"$nombre\" />$LANG_FULLDISK $nombre ($tamanio GB)</label><br/>"
		opciones="$opciones\n$opcion"
		awk '/'$nombre'[0-9]/ && $3>1 {print $4": "$3}' /proc/partitions > $DIRTMP/particiones.txt
		while read particion
		do
			nombre=${particion//:*/}
			tamanio=$(verificarTamanioDestino "$nombre")
			if [ $tamanio -gt 0 ]; then
				opcion="<label><input type='radio' name='PARTICIONROOT' value=\"$nombre\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$LANG_PARTITION $nombre ($tamanio GB)</label><br/>"
				opciones="$opciones\n$opcion"
			fi
		done < $DIRTMP/particiones.txt
	done < $DIRTMP/discos.txt
	echo -e "$opciones"
}

function seleccionarParticionROOT() {

	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaParticionROOT.html > $DIRTMP/HELP
	SIGUIENTEPASO="seleccionarstage"
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	
	listarParticionesAuto > $DIRTMP/PARTICIONES
	[ "x$1" != "x" ] && ERRORPARTICION="<p>$LANG_PARTITION2SMALL</p>"
	
	procesarModeloHTML $DIRBASE/modulos/$MODULO/seleccionarParticionROOT.html
	
	touch /tmp/PARTICIONAR
	
}

function seleccionarStage() {

	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaSeleccionarStage.html > $DIRTMP/HELP
	ultimostage=${STAGES//* /}
	for stage in $STAGES
	do
		nombre="NOMBRE_$stage"
		tamanio="TAMANIO_MINIMO_$stage"
		[[ "x$stage" = "x$ultimostage" && $STAGESINDEPENDIENTES -ne 1 ]] && checked="checked" || checked=""
		opcion="<label><input type='radio' name='STAGEAINSTALAR' value=\"$stage\" $checked />${!nombre} (${!tamanio} GB)</label><br/>"
		opciones="$opciones\n$opcion"
	done
	SELECCIONARSTAGES=$opciones
	SIGUIENTEPASO="seleccionarzonahoraria"
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	procesarModeloHTML $DIRBASE/modulos/$MODULO/seleccionarStage.html

}

function seleccionarZonaHoraria() {

	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaZonaHoraria.html > $DIRTMP/HELP
	zoneinfo="<select name='ZONAHORARIA' size='5'>"
	while read zona
	do
		zoneinfo="$zoneinfo\n\t<option value='${zona//\//__}'>$zona</option>"
	done < $DIRBASE/configuracion/zoneinfo.txt
	SELECCIONARZONAHORARIA="$zoneinfo\n</select>"
	SIGUIENTEPASO="confirmacion"
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	procesarModeloHTML $DIRBASE/modulos/$MODULO/seleccionarZonaHoraria.html

}

function confirmarInstalacion() {

	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaConfirmacion.html > $DIRTMP/HELP
	SIGUIENTEPASO="ejecutarinstalacion"
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	procesarModeloHTML $DIRBASE/modulos/$MODULO/confirmacion.html

}

function progresoInstalacion() {
	local AUX
	
	PROGRESO=$(tail -n 1 /tmp/progreso.log)
	PORCENTAJE="$(echo $PROGRESO | awk -F '|' '{ print $1 }')"
	TITULO="$(echo $PROGRESO | awk -F '|' '{ print $2 }')"
	DESCRIPCION="$(echo $PROGRESO | awk -F '|' '{ print $3 }')"
	RND=$RANDOM
	echo "RND=$RND" > $DIRTMP/PARAMETOSGET
	if [ "x$PORCENTAJE" = "x100%" ]; then
		SIGUIENTEPASO="finalizarinstalacion"
	else
		SIGUIENTEPASO="progresoinstalacion"
	fi
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	HEADERTAGS="<meta http-equiv='Refresh' content='5; $URLBASE""cgi-bin/instalador-web.sh?MODULOACTUAL=$MODULO&SIGUIENTEPASO=$SIGUIENTEPASO&RND=$RND'/>"
	procesarModeloHTML $DIRBASE/modulos/$MODULO/progresoInstalacion.html > $DIRTMP/CONTENT
	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaProgresoInstalacion.html > $DIRTMP/HELP

}

function ejecutarIntalacion() {

	ZONAHORARIA=${ZONAHORARIA//__/\/}
	datosDeInstalacion -txt IDIOMA STAGEAINSTALAR ZONAHORARIA PARTICIONROOT MODULOACTUAL DIRBASE > /tmp/datosdeinstalacion
	echo "0%|Iniciando instalacion|Presione Refresh para ver el progreso de la instalacion..." > /tmp/progreso.log
	progresoInstalacion

}

function finalizarInstalacion() {

	SIGUIENTEPASO="reiniciar"
	datosDeInstalacion SIGUIENTEPASO >> $DIRTMP/DATOSDEINSTALACION
	HEADERTAGS="<meta http-equiv='Refresh' content='60; $URLBASE""cgi-bin/instalador-web.sh?MODULOACTUAL=$MODULO&SIGUIENTEPASO=$SIGUIENTEPASO'/>"
	procesarModeloHTML $DIRBASE/modulos/$MODULO/agradecimientos.html > $DIRTMP/CONTENT

}

datosDeInstalacion IDIOMA MODULOACTUAL MODULOANTERIOR STAGEAINSTALAR ZONAHORARIA PARTICIONROOT  >> $DIRTMP/DATOSDEINSTALACION

rm /tmp/PARTICIONAR

case $SIGUIENTEPASO in
	"confirmacion")
		if [ $(verificarTamanioDestino $PARTICIONROOT) -gt 0 ]; then
			confirmarInstalacion > $DIRTMP/CONTENT
		else
			SIGUIENTEPASO=""
			seleccionarParticionROOT $LANG_PARTITION2SMALL  > $DIRTMP/CONTENT
		fi
	;;
	"progresoinstalacion")
		progresoInstalacion > $DIRTMP/CONTENT
	;;
	"ejecutarinstalacion")
		ejecutarIntalacion > $DIRTMP/CONTENT
	;;
	"finalizarinstalacion")
		finalizarInstalacion > $DIRTMP/CONTENT
	;;
	"reiniciar")
		echo $LANG_REBOOTING > $DIRTMP/CONTENT
		: > /tmp/reiniciar
	;;
	"seleccionarzonahoraria")
		if [ $(verificarTamanioDestino $PARTICIONROOT) -gt 0 ]; then
			seleccionarZonaHoraria > $DIRTMP/CONTENT
		else
			SIGUIENTEPASO=""
			seleccionarParticionROOT $LANG_PARTITION2SMALL  > $DIRTMP/CONTENT
		fi
	;;
	"seleccionarstage")
		seleccionarStage > $DIRTMP/CONTENT
	;;
	*)
		seleccionarParticionROOT > $DIRTMP/CONTENT
	;;
esac

mostrarPagina
