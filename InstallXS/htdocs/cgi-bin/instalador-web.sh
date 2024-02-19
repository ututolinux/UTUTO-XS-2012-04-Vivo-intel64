#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

# echo "$0" 1>&2
rm -rf /tmp/instalador-ututo-*

source ../configuracion/instalador-web.conf

rm -rf $DIRTMP
mkdir -p $DIRTMP

source $DIRBASE/librerias/libweb.sh

source $DIRBASE/idiomas/$IDIOMA/principal.sh
declare TITLE="$LANG_DEFAULT_TITLE"
declare HEADERTAGS

declare -r gQUERY="$QUERY_STRING $(cat /dev/stdin)"
for query in ${gQUERY//&/ }
do
	nvar=${query%%=*}
	declare ${query}
done

[ "x$MODULOACTUAL" = "x" ] && MODULOACTUAL=$MODULOINICIAL

if [ -f $DIRBASE/modulos/$MODULOACTUAL.sh ]; then
	[ -f $DIRBASE/idiomas/$IDIOMA/$MODULOACTUAL.sh ] && source $DIRBASE/idiomas/$IDIOMA/$MODULOACTUAL.sh
	source $DIRBASE/modulos/$MODULOACTUAL.sh
else
	echo "$LANG_ERR_NO_MODULE" > $DIRTMP/CONTENT
fi

# rm -rf $DIRTMP
