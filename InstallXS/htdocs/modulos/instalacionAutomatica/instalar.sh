#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

# Indice de la instalacion:
# 
# 0.- Leer las opciones seleccionadas por el usuario
# 1.- Formatear la particion ROOT
# 	1.1.- Eliminar particiones existentes
# 	1.2.- Crear particion ROOT
# 	1.3.- Formatear particion ROOT
# 	1.4.- Montar particion ROOT
# 2.- Crear archivo swap y activar
# 3.- Instalar stage 1
# 4.- Instalar kernels
# 5.- Instalar stages 2 y 3
# 6.- Crear fstab
# 7.- Configurar lilo
# 8.- Montar /proc
# 9.- Reemplazar /admin instalado por admin de CD
# 10.- Ejecutar inicial.run
# 	10.1.- Copiar inicial.run
# 	10.2.- Ejecutar con chroot
# 11.- Restaurar /admin instalado

: > /tmp/instalar.log
exec 2>&1
exec 1>/tmp/instalar.log

cd $(dirname $0)
pwd

source ../../configuracion/instalador-web.conf
source ../../librerias/libinstalar.sh

########################## <CODIGO TEMPORAL PARA DESARROLLO> ###############
if [ "x$(cat /etc/ututo-release)" = "xUTUTO XS 2007 Install CD" ]; then
	: > /tmp/progreso.log
	for ((i=1; i < 11; i++))
	do
		progresoInstalacion "${i}0" "Paso $i" "Estamos en $i"
		sleep 5
	done
else
########################## </CODIGO TEMPORAL PARA DESARROLLO> ###############

# 0.- Leer las opciones seleccionadas por el usuario
source /tmp/datosdeinstalacion

progresoInstalacion 1 "1.- Create ROOT partition"
# 1.- Formatear la particion ROOT
# 	1.1.- Eliminar particiones existentes
# 	1.2.- Crear particion ROOT
# 	1.3.- Formatear particion ROOT
if [ "$(awk '/'$PARTICIONROOT'$/ { print $2 }' /proc/partitions)" -eq 0 ]; then
	# Si es un disco completo, hacer una sola partición
	progresoInstalacion 3 "Create ROOT partition" "Usando el disco completo $PARTICIONROOT"
	formatearDiscoCompleto $PARTICIONROOT
	progresoInstalacion 5 "Create ROOT partition" "Se ha creado una particion usando todo el disco $PARTICIONROOT"
	PARTICIONROOT="${PARTICIONROOT}1"
fi
# Formatear la particion como EXT3
progresoInstalacion 7 "Create ROOT partition" "Formateando /dev/$PARTICIONROOT"
for ((i=0; i<10; i++)); do
	[ -b /dev/$PARTICIONROOT ] && break
	sleep 1
done
if [ $(awk '/'$PARTICIONROOT'$/ { print $2 }' /proc/partitions | wc -l) -ne 1 -o ! -b "/dev/$PARTICIONROOT" ]; then
	echo "Error $PARTICIONROOT no es un dispositivo de bloques"
	exit 1
fi
sync ; sync ; sync
umount /dev/$PARTICIONROOT
sleep 2
mkdir /mnt/noformat
mount /dev/$PARTICIONROOT /mnt/noformat
if [ -e /mnt/noformat/home ]; then
    sync ; sync ; sync
    umount /dev/$PARTICIONROOT
    rm -rf /mnt/noformat
    sleep 2
else
    TESTPART=`mount | grep "/dev/$PARTICIONROOT"`
    if [ "$TESTPART" = "" ];then
	sync ; sync ; sync
	umount /dev/$PARTICIONROOT
	rm -rf /mnt/noformat
	sleep 2
	if [ "$FORMATOPORDEFECTO" = "xfs" ];then
	    mkfs.$FORMATOPORDEFECTO -f /dev/$PARTICIONROOT
	else
	    mkfs.$FORMATOPORDEFECTO /dev/$PARTICIONROOT
	fi
    else
	sync ; sync ; sync
	umount /dev/$PARTICIONROOT
	rm -rf /mnt/noformat
	sleep 2
    fi
fi
# 	1.4.- Montar particion ROOT
progresoInstalacion 9 "Create ROOT partition" "Montando $PARTICIONROOT"
[ ! -d /mnt/$PARTICIONROOT ] && mkdir -p /mnt/$PARTICIONROOT
mount /dev/$PARTICIONROOT /mnt/$PARTICIONROOT
DIRECTORIOROOT="/mnt/$PARTICIONROOT"

# 2.- Crear archivo swap y activar
declare particionswapprevia=$(sfdisk -d | grep 'Id=82' | awk '{print $1}' | head -n 1)
if [ "x$particionswapprevia" = "x" ]; then
	progresoInstalacion 11 "Create SWAP file" "Creando archivo de memoria de intercambio $DIRECTORIOROOT/swap"
	dd if=/dev/zero of=/mnt/$PARTICIONROOT/swap bs=1024 count=524288
	mkswap $DIRECTORIOROOT/swap
	swapon $DIRECTORIOROOT/swap
else
	progresoInstalacion 11 "Create SWAP file" "Utilizando memoria de intercambio existente $particionswapprevia"
	mkswap $particionswapprevia
	swapon $particionswapprevia
fi

[[ $STAGESINDEPENDIENTES -eq 1 ]] && STAGES=$STAGEAINSTALAR

#if [ ! -e /tmp/netinstallxs ]; then
#    for stage in $STAGES
#    do
#	archivos="${stage}_ARCHIVOS"
#	descripcion="${stage}_DESCRIPCION"
#	# 3.- Descargar stage
#	for archivo in ${!archivos}
#	do
#	    progresodh="0"
#	    progresoInstalacion ${progresodh} "Downloading ${!descripcion}" "Downloading ${archivo}(0KB/s)"
#	    actual=`pwd`
#	    cd $DIRECTORIOROOT
#	    wget -c --background http://packages.ututo.org/utiles/stages2010/${archivo}
#	    sleep 2
#	    for ((i=1; i>0; i=`ps ax | grep "wget" | grep "utiles" | wc -l`)); do
#		porcentajedh=`cat wget-log | tail -n 2 | head -n 1 | cut -d "s" -f 2  | cut -d "%" -f 1 | sed "s/ //" | sed "s/ //" | sed "s/ //" | sed "s/ //"`
#		voldh=`cat wget-log | tail -n 2 | head -n 1 | cut -d " " -f 1`
#		velocidaddh=`cat wget-log | tail -n 2 | head -n 1 | sed "s/............................................................//"`
#		progreso="$porcentajedh"
#		progresoInstalacion ${porcentajedh} "Downloading ${!descripcion}" "Downloading ${archivo} (${voldh} ${velocidaddh})"
#		sleep 5
#		i=`ps ax | grep "wget" | grep "utiles" | wc -l`
#	    done
#	    rm -rf $DIRECTORIOROOT/wget-log*
#	    cd $actual
#	done
#	cd $actual
#    done
#    cd $actual
#fi

for stage in $STAGES
do
	path="${stage}_PATH"
	archivos="${stage}_ARCHIVOS"
	files="FILES_${stage}"
	descripcion="${stage}_DESCRIPCION"
	progreso="${stage}_PROGRESO"
	avance="${stage}_AVANCE"
	# 3.- Instalar stage
	for archivo in ${!archivos}
	do
	  if [ "$archivo" = "COPY" ];then
	    if [ ! -e /mnt/cdrom/image.squashfs ]; then
		progresodh="0"
		progresoInstalacion ${progresodh} "Downloading ${!descripcion}" "Downloading image.squashfs (Okb 0KB/s)"
		actual=`pwd`
		cd $DIRECTORIOROOT
		#wget -c --background http://packages.ututo.org/utiles/stages2011/i686/image.squashfs
		wget -c --background $DOWNLOAD_NETINSTALL
		sleep 2
		for ((i=1; i>0; i=`ps ax | grep "wget" | grep "utiles" | wc -l`)); do
		    porcentajedh=`cat wget-log | tail -n 2 | head -n 1 | cut -d "s" -f 2  | cut -d "%" -f 1 | sed "s/ //" | sed "s/ //" | sed "s/ //" | sed "s/ //"`
		    voldh=`cat wget-log | tail -n 2 | head -n 1 | cut -d " " -f 1`
		    velocidaddh=`cat wget-log | tail -n 2 | head -n 1 | sed "s/............................................................//"`
		    progreso="$porcentajedh"
		    progresoInstalacion ${porcentajedh} "Downloading ${!descripcion}" "Downloading image.squashfs (${voldh} ${velocidaddh})"
		    sleep 5
		    i=`ps ax | grep "wget" | grep "utiles" | wc -l`
		done
		rm -rf $DIRECTORIOROOT/wget-log*
		cd $actual
		mkir /mnt/livecdlow
		mount -t squashfs -o loop $DIRECTORIOROOT/image.squashfs /mnt/livecdlow
		if [ ! -e /mnt/livecdlow/ututo.lastversion ];then
		    progresoInstalacion ${progresodh} "Downloading ${!descripcion}" "Downloading image.squashfs (DOWNLOAD ERROR!!!)"
		    swapoff $DIRECTORIOROOT/swap
		    umount $DIRECTORIOROOT/proc
		    umount $DIRECTORIOROOT
		    sleep 60
		    reboot
		fi
	    fi
	    if [ -e /mnt/livecdlow/ututo.lastversion ];then
		livecd="livecdlow"
	    else
		livecd="livecd"
	    fi
	    SERIAL=`date +%B-%d-%Y`
	    progresoInstalacion "20" "Copying files (admin)..." "${!descripcion}"
	    #unsquashfs -f -d /tmp/gentooxs fs-XS2012-02-intel32-Vivo.squashfs /root
	    
	    #nice -n -10 cp -a /mnt/$livecd/ututo.lastversion $DIRECTORIOROOT
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /ututo.lastversion

	    #nice -n -10 cp -a /mnt/$livecd/ututo.lastversion.disponibles $DIRECTORIOROOT

	    #nice -n -10 cp -a /mnt/$livecd/system.name $DIRECTORIOROOT
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /system.name

	    #nice -n -10 cp -a /mnt/$livecd/System.map $DIRECTORIOROOT
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /System.map

	    #nice -n -10 cp -a /mnt/$livecd/srv $DIRECTORIOROOT
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /srv

	    if [ -e $DIRECTORIOROOT/admin ]; then
		mv $DIRECTORIOROOT/admin $DIRECTORIOROOT/admin-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/admin $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /admin
	    sleep 2

	    progresoInstalacion "21" "Copying files (bin)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/bin ]; then
		mv $DIRECTORIOROOT/bin $DIRECTORIOROOT/bin-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/bin $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /bin
	    rm -rf $DIRECTORIOROOT/bin/installXS
	    sleep 2

	    progresoInstalacion "22" "Copying files (boot-dev)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/boot ]; then
		mv $DIRECTORIOROOT/boot $DIRECTORIOROOT/boot-upgrade-$SERIAL
	    fi
	    if [ -e $DIRECTORIOROOT/dev ]; then
		mv $DIRECTORIOROOT/dev $DIRECTORIOROOT/dev-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/boot $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /boot
	    #nice -n -10 cp -a /mnt/$livecd/dev $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /dev
	    sleep 2

	    progresoInstalacion "23" "Copying files (etc)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/etc ]; then
		mv $DIRECTORIOROOT/etc $DIRECTORIOROOT/etc-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/opt/stages/etc $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /etc
	    rm -rf $DIRECTORIOROOT/etc/firewalldesktop.sh
	    rm -rf $DIRECTORIOROOT/etc/local.d/01InstallXS.start
	    rm -rf $DIRECTORIOROOT/etc/firebird
	    rm -rf $DIRECTORIOROOT/etc/gconf
	    rm -rf $DIRECTORIOROOT/etc/psad
	    rm -rf $DIRECTORIOROOT/etc/skel
	    rm -rf $DIRECTORIOROOT/etc/splash
	    rm -rf $DIRECTORIOROOT/etc/mono
	    rm -rf $DIRECTORIOROOT/etc/ssl
	    rm -rf $DIRECTORIOROOT/etc/makedev.d
	    rm -rf $DIRECTORIOROOT/etc/openldap
	    rm -rf $DIRECTORIOROOT/etc/php
	    rm -rf $DIRECTORIOROOT/etc/texmf
	    rm -rf $DIRECTORIOROOT/etc/prelink.cache
	    rm -rf $DIRECTORIOROOT/etc/ld.so.cache
	    rm -rf $DIRECTORIOROOT/etc/termcap
	    rm -rf $DIRECTORIOROOT/etc/avrdude.conf
	    mv $DIRECTORIOROOT/opt $DIRECTORIOROOT/opt.bak
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /opt/stages/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/firebird $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/gconf $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/psad $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/skel $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/splash $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/mono $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/ssl $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/makedev.d $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/openldap $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/php $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/texmf $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/prelink.cache $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/ld.so.cache $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/termcap $DIRECTORIOROOT/etc
	    mv $DIRECTORIOROOT/opt/stages/etc/avrdude.conf $DIRECTORIOROOT/etc
	    rm -rf $DIRECTORIOROOT/opt
	    mv $DIRECTORIOROOT/opt.bak $DIRECTORIOROOT/opt
	    rm -rf $DIRECTORIOROOT/etc/X11/startDM.sh
	    mv $DIRECTORIOROOT/etc/X11/startDM.sh.xs $DIRECTORIOROOT/etc/X11/startDM.sh
	    sleep 2

	    progresoInstalacion "27" "Copying files (lib)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/lib ]; then
		mv $DIRECTORIOROOT/lib $DIRECTORIOROOT/lib-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/lib $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /lib
	    sleep 2

	    progresoInstalacion "28" "Copying files (mnt-media-proc)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/mnt ]; then
		mv $DIRECTORIOROOT/mnt $DIRECTORIOROOT/mnt-upgrade-$SERIAL
	    fi
	    if [ -e $DIRECTORIOROOT/media ]; then
		mv $DIRECTORIOROOT/media $DIRECTORIOROOT/media-upgrade-$SERIAL
	    fi
	    if [ -e $DIRECTORIOROOT/proc ]; then
		mv $DIRECTORIOROOT/proc $DIRECTORIOROOT/proc-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/mnt $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /mnt
	    #nice -n -10 cp -a /mnt/$livecd/media $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /media
	    #nice -n -10 cp -a /mnt/$livecd/proc $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /proc
	    sleep 2

	    progresoInstalacion "29" "Copying files (opt)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/opt ]; then
		mv $DIRECTORIOROOT/opt $DIRECTORIOROOT/opt-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/opt $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /opt
	    rm -rf $DIRECTORIOROOT/opt/stages

	    progresoInstalacion "34" "Copying files (root-sbin)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/root ]; then
		nice -n -10 cp -a $DIRECTORIOROOT/root $DIRECTORIOROOT/root-upgrade-$SERIAL
		rm -rf $DIRECTORIOROOT/root-upgraded
		touch $DIRECTORIOROOT/root-upgraded
		cp $DIRECTORIOROOT/etc-upgrade-$SERIAL/etc/passwd $DIRECTORIOROOT/etc/
		cp $DIRECTORIOROOT/etc-upgrade-$SERIAL/etc/shadow $DIRECTORIOROOT/etc/
		chown root.root $DIRECTORIOROOT/etc/passwd &
		chown root.root $DIRECTORIOROOT/etc/shadow &
	    fi
	    if [ -e $DIRECTORIOROOT/sbin ]; then
		mv $DIRECTORIOROOT/sbin $DIRECTORIOROOT/sbin-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/root $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /root
	    #nice -n -10 cp -a /mnt/$livecd/sbin $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /sbin
	    sleep 2

	    progresoInstalacion "36" "Copying files (sys-tmp)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/tmp ]; then
		mv $DIRECTORIOROOT/tmp $DIRECTORIOROOT/tmp-upgrade-$SERIAL
	    fi
	    if [ -e $DIRECTORIOROOT/sys ]; then
		mv $DIRECTORIOROOT/sys $DIRECTORIOROOT/sys-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/sys $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /sys
	    #nice -n -10 cp -a /mnt/$livecd/tmp $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /tmp
	    sleep 2

	    progresoInstalacion "39" "Copying files (var)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/var ]; then
		mv $DIRECTORIOROOT/var $DIRECTORIOROOT/var-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/opt/stages/var $DIRECTORIOROOT &
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /var
	    sleep 2

	    progresoInstalacion "60" "Copying files (User home)..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/home ]; then
		nice -n -10 cp -a $DIRECTORIOROOT/home $DIRECTORIOROOT/home-upgrade-$SERIAL
	    fi
	    #if [ ! -e $DIRECTORIOROOT/home/ututo ]; then
		#nice -n -10 cp -a /mnt/$livecd/opt/stages/home $DIRECTORIOROOT &
		unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /home
	    #fi
	    sleep 2

	    progresoInstalacion "60" "Copying 8GB (usr) take much time! be patient!..." "${!descripcion}"
	    if [ -e $DIRECTORIOROOT/usr ]; then
		mv $DIRECTORIOROOT/usr $DIRECTORIOROOT/usr-upgrade-$SERIAL
	    fi
	    #nice -n -10 cp -a /mnt/$livecd/usr $DIRECTORIOROOT
	    unsquashfs -f -d $DIRECTORIOROOT /mnt/cdrom/image.squashfs /usr
	    rm -rf $DIRECTORIOROOT/usr/bin/install-vivo.sh
	    rm -rf $DIRECTORIOROOT/usr/share/applications/Instalar_XS.desktop
	    #nice -n -10 cp -a /mnt/$livecd/opt/stages/lib $DIRECTORIOROOT

	    #rm -rf $DIRECTORIOROOT/var/lib/slocate
	    #cp -a /mnt/$livecd/opt/rom/slocate $DIRECTORIOROOT/var/lib/
	    #rm -rf $DIRECTORIOROOT/var/db
	    #cp -a /mnt/$livecd/opt/rom/db $DIRECTORIOROOT/var/
	    #rm -rf $DIRECTORIOROOT/var/lib/texmf
	    #cp -a /mnt/$livecd/opt/rom/texmf $DIRECTORIOROOT/var/lib/
	    #cp -a /mnt/$livecd/System.map $DIRECTORIOROOT
	    #rm -rf $DIRECTORIOROOT/opt/rom
	    #progresoInstalacion "48" "Copying files (linux modules)..." "${!descripcion}"
	    #cp -a /mnt/$livecd/opt/stages/lib $DIRECTORIOROOT
	    #progresoInstalacion "52" "Copying files (linux source)..." "${!descripcion}"
	    #cp -a /mnt/$livecd/opt/stages/usr $DIRECTORIOROOT
	    #chown ututo.ututo $DIRECTORIOROOT/home/ututo
	    #chown -R ututo.ututo $DIRECTORIOROOT/home/ututo
	    #cp -a /mnt/$livecd/opt/stages/proc $DIRECTORIOROOT
	    #cp -a /mnt/$livecd/opt/stages/srv $DIRECTORIOROOT
	    #cp -a /mnt/$livecd/opt/stages/portage $DIRECTORIOROOT/usr/
	    #progresoInstalacion "60" "Erasing tmp files..." "UTUTO-XS Vivo!"
	    #rm -rf $DIRECTORIOROOT/opt/stages
	    #rm -rf $DIRECTORIOROOT/home/ututo/Desktop/*.desktop
	  else
	    progresoInstalacion ${!progreso} "Installing ${!descripcion}" "Installing ${!stage}(${archivo})"
	    if [ -e /tmp/netinstallxs ]; then
		instalarStage "$DIRECTORIOROOT/${archivo}" ${!files} ${!avance} $DIRECTORIOROOT/ "Installing ${!descripcion}" "Installing ${!stage}(${archivo})"
	    else
		instalarStage "${!path}/${archivo}" ${!files} ${!avance} $DIRECTORIOROOT/ "Installing ${!descripcion}" "Installing ${!stage}(${archivo})"
	    fi
	    rm -rf $DIRECTORIOROOT/${archivo}
	  fi
	  if [ ! -e /mnt/cdrom/image.squashfs ]; then
	    if [ -e /mnt/livecdlow/ututo.lastversion ];then
	        umount /mnt/livecdlow
	        if [ -e $DIRECTORIOROOT/image.squashfs ];then
		    rm -rf $DIRECTORIOROOT/image.squashfs
		fi
	    fi
	  fi
	done
done

# 6.- Crear fstab
progresoInstalacion 65 "Configure system" "Configurando fstab"
crearFstab

# 7.- Configurar lilo
progresoInstalacion 67 "Configure system" "Configurando lilo"
configurarLilo

# 8.- Montar /proc
progresoInstalacion 69 "Configure system" "Mountando /proc en disco destino"
mkdir -p $DIRECTORIOROOT/proc
mount -t proc proc $DIRECTORIOROOT/proc

# 9.- Reemplazar /admin instalado por admin de CD
# progresoInstalacion 71 "Configure system" "Reemplazando admin"
#mv $DIRECTORIOROOT/admin $DIRECTORIOROOT/admin.bak
#cp -R /mnt/instalar/admin $DIRECTORIOROOT/

# 	9.1.- Prepara ejecución de inicial.run
#echo $IDIOMA > $DIRECTORIOROOT/admin/ututoe.l

# 10.- Ejecutar inicial.run
# 	10.1.- Copiar inicial.run
# 	10.2.- Ejecutar con chroot
progresoInstalacion 73 "Configure system" "Ejecutando tareas de configuración final. <br>Esto puede demorar, espere..."
cp ./inicial.run.$STAGEAINSTALAR $DIRECTORIOROOT/inicial.run
chmod +x $DIRECTORIOROOT/inicial.run
$DIRBASE/bin/runasroot.sh "/usr/bin/chroot $DIRECTORIOROOT /bin/bash -c /inicial.run"

# 10.5.- Instalar passwd y shadow
#[[ -f ./passwd.$STAGEAINSTALAR ]] && cp ./passwd.$STAGEAINSTALAR $DIRECTORIOROOT/etc/passwd
#[[ -f ./shadow.$STAGEAINSTALAR ]] && cp ./shadow.$STAGEAINSTALAR $DIRECTORIOROOT/etc/shadow

# 11.- Restaurar /admin instalado
#progresoInstalacion 85 "Configure system" "Restaurando admin"
#rm -rf $DIRECTORIOROOT/admin
# mv $DIRECTORIOROOT/admin.bak $DIRECTORIOROOT/admin



# FIN
swapoff $DIRECTORIOROOT/swap
umount $DIRECTORIOROOT/proc
umount $DIRECTORIOROOT
progresoInstalacion 100 "Installation completed" "Se completo la instalacion del sistema"


########################## <CODIGO TEMPORAL PARA DESARROLLO> ###############
fi
########################## </CODIGO TEMPORAL PARA DESARROLLO> ###############
