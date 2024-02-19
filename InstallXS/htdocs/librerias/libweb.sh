#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $


function datosDeInstalacion() {
	local formato=html

	if [ "$1" = "-txt" ]; then
		formato=txt
		shift
	fi
	for dato in "$@"
	do
 		if [ "x${!dato}" != "x" ]; then
			if [ $formato = html ]; then
				echo -e "<input type=hidden name=\"$dato\" value=\"${!dato}\" />"
			else
				echo "$dato='"${!dato}"'"
			fi
 		fi
	done
}

function procesarModeloHTML() {
	local tag
	local valor
	tmphtml=$DIRTMP/${1//*\//}
	cp $1 $tmphtml

	for tag in $(egrep -o "<\!--WEB_[[:alnum:]_]*-->" $1 | sed -r "s/<\!--WEB_(.*)-->/\1/g")
	do
		valor=${!tag}
		echo "<!--"$tag':' $valor"-->" >> $DIRTMP/tags.log
		[ ! -f $DIRTMP/$tag ] && echo -e "$valor" > $DIRTMP/$tag
#   		sed -i "s/<\!--WEB_$tag-->/$valor/g" $tmphtml
		sed -i -e "s/<!--WEB_$tag-->/\n<!--WEB_$tag-->\n/" $tmphtml
		sed -i -e "/<!--WEB_$tag-->/ r $DIRTMP/$tag" $tmphtml
		sed -i -e "s/<!--WEB_$tag-->//" $tmphtml
	done
	cat $tmphtml
}

function mostrarPagina() {
	echo "Content-Type: text/html"
	echo "Expire: -1"
	echo "Pragma: no-cache"
	echo
	procesarModeloHTML $DIRBASE/apariencias/$APARIENCIA/modelo.html
}
