#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $
 
MODULO="seleccionarModuloInstalador"
 
function listaModulos() {
	local modulo
	local opcion
	
	for f in $(ls -1 $DIRBASE/modulos/*.sh | grep -v "$MODULOINICIAL")
	do 
		modulo=$(echo $f | sed -e "s/.*\///g" -e "s/\.sh$//g")
		echo "<option value="$modulo">$modulo</option>"
	done
	
}
 
function seleccionarModuloInstalador() {

	TITLE="$LANG_DEFAULT_TITLE"
	procesarModeloHTML $DIRBASE/idiomas/$IDIOMA/$MODULO/ayudaSeleccionarModuloInstalador.html > $DIRTMP/HELP
	
	listaModulos > $DIRTMP/MODULOSDISPONIBLES
	
	procesarModeloHTML $DIRBASE/modulos/$MODULO/seleccionarModuloInstalador.html

}

seleccionarModuloInstalador  > $DIRTMP/CONTENT
mostrarPagina
