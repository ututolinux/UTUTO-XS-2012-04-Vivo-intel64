#!/bin/bash
# InstallXS v0.1
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

function progresoInstalacion() {
	AVAN=`cat /tmp/avan.txt`
	if [ "$AVAN" = "" ];then
	    AVAN="-"
	fi
	if [ "$AVAN" = "-" ];then
	    AVAN="+"
	fi
	if [ "$AVAN" = "+" ];then
	    AVAN="o"
	fi
	if [ "$AVAN" = "o" ];then
	    AVAN="O"
	fi
	if [ "$AVAN" = "O" ];then
	    AVAN="X"
	fi
	if [ "$AVAN" = "X" ];then
	    AVAN="x"
	fi
	if [ "$AVAN" = "x" ];then
	    AVAN="+"
	fi
	echo $AVAN > /tmp/avan.txt
	echo "$1% [$AVAN]|$2|$3" >> /tmp/progreso.log
}

function configurarLilo() {
	local DISCO=$(echo $PARTICIONROOT | sed -r "s/[0-9]+$//")
	local LILOCONF="/mnt/$PARTICIONROOT/etc/lilo.conf"
	local GRUBCONF="/mnt/$PARTICIONROOT/boot/grub/grub.conf"
	local ROOTDEV="/dev/$PARTICIONROOT"
	

	cp ./lilo.conf.$STAGEAINSTALAR $LILOCONF
	cp ./grub.conf.$STAGEAINSTALAR $GRUBCONF
	sed -i "s/DISCO/$DISCO/" $LILOCONF
	#if [ "`lsmod | grep -v pata_acpi | grep -v pata_sis| grep pata`" = "" ];then
	#    if [ "`lsmod | grep -v scsi_wait_scan | grep scsi`" = "" ];then
	#	KERNELxDEFECTO=`echo $KERNELxDEFECTO | sed "s/ata/ide/" | sed "s/26313/26313/"`
	#    else
	#	KERNELxDEFECTO=`echo $KERNELxDEFECTO | sed "s/ata/ides/" | sed "s/26313/26313/"`
	#    fi
	#fi
	sed -i "s/default=UTUTO/default=$KERNELxDEFECTO/" $LILOCONF
	DEVICESWAP=$(sfdisk -d | grep 'Id=82' | awk '{print $1}' | head -n 1)
	if [ "$DEVICESWAP" = "" ];then
	    DEVICESWAP="$ROOTDEV"
	fi

	# Bootable kernel image
	#for kernel in $KERNELS; do
		#version="VERSION_KERNEL_$kernel"
		#etiqueta="ETIQUETA_KERNEL_$kernel"
		#parametros="PARAMETROS_KERNEL_$kernel"
		#silencioso="SILENCIOSO_KERNEL_$kernel"
		echo "image=/boot/kernel-$VERSION_KERNEL" >> $LILOCONF
		echo "       label=$ETIQUETA_KERNEL" >> $LILOCONF
		echo "       root=/dev/ram0" >> $LILOCONF
		echo "       initrd=/boot/initramfs-$VERSION_KERNEL" >> $LILOCONF
		echo "       append=\"$PARAMETROS_KERNEL\"" >> $LILOCONF
		echo "       addappend=\"real_root=$ROOTDEV tuxonice_resume=swap:$DEVICESWAP resume=swap:$DEVICESWAP\"" >> $LILOCONF
		echo "" >> $LILOCONF
	#done
	BUSGRUB="0"
	HDDGRUB="0"
	DEVICEGRUB=`echo $ROOTDEV | cut -d "/" -f 3`
	DEVICESWAPG=`echo $DEVICESWAP | cut -d "/" -f 3`
	case $ROOTDEV in
	/dev/sda1 )
		    BUSGRUB="0"
		    HDDGRUB="0"
		    ;;
	/dev/sda2 )
		    BUSGRUB="0"
		    HDDGRUB="1"
		    ;;
	/dev/sda3 )
		    BUSGRUB="0"
		    HDDGRUB="2"
		    ;;
	/dev/sda4 )
		    BUSGRUB="0"
		    HDDGRUB="3"
		    ;;
	/dev/sdb1 )
		    BUSGRUB="1"
		    HDDGRUB="0"
		    ;;
	/dev/sdb2 )
		    BUSGRUB="1"
		    HDDGRUB="1"
		    ;;
	/dev/sdb3 )
		    BUSGRUB="1"
		    HDDGRUB="2"
		    ;;
	/dev/sdb4 )
		    BUSGRUB="1"
		    HDDGRUB="3"
		    ;;
	/dev/sdc1 )
		    BUSGRUB="2"
		    HDDGRUB="0"
		    ;;
	/dev/sdc2 )
		    BUSGRUB="2"
		    HDDGRUB="1"
		    ;;
	/dev/sdc3 )
		    BUSGRUB="2"
		    HDDGRUB="2"
		    ;;
	/dev/sdc4 )
		    BUSGRUB="2"
		    HDDGRUB="3"
		    ;;
	/dev/sdd1 )
		    BUSGRUB="3"
		    HDDGRUB="0"
		    ;;
	/dev/sdd2 )
		    BUSGRUB="3"
		    HDDGRUB="1"
		    ;;
	/dev/sdd3 )
		    BUSGRUB="3"
		    HDDGRUB="2"
		    ;;
	/dev/sdd4 )
		    BUSGRUB="3"
		    HDDGRUB="3"
		    ;;
	esac
	sed -i "s/BUSGRUB/$BUSGRUB/" $GRUBCONF
	sed -i "s/HDDGRUB/$HDDGRUB/" $GRUBCONF
	sed -i "s/BUSGRUB/$BUSGRUB/" $GRUBCONF
	sed -i "s/HDDGRUB/$HDDGRUB/" $GRUBCONF

	sed -i "s/DEVICEROOT/$DEVICEGRUB/" $GRUBCONF
	sed -i "s/DEVICEROOT/$DEVICEGRUB/" $GRUBCONF

	sed -i "s/DEVICESWAP/$DEVICESWAPG/" $GRUBCONF
	sed -i "s/DEVICESWAP/$DEVICESWAPG/" $GRUBCONF
	sed -i "s/DEVICESWAP/$DEVICESWAPG/" $GRUBCONF
	sed -i "s/DEVICESWAP/$DEVICESWAPG/" $GRUBCONF

# 	echo "image=/boot/memtest86plus/memtest.bin" >> $LILOCONF
# 	echo "       label=Memtest86Plus" >> $LILOCONF
	echo "" >> $LILOCONF
	
	# Other non-free local operating systems
	local -a vpartitions
	local i=0
	local j=1
	for filesystem in $OTHER_FS; do
		vpartitions[i++]=`LANGUAGE="en" sfdisk -l | grep $filesystem | awk -F \  /$filesystem/'{print $1}'`
	done
	mkdir /mnt/non_gnu
	for partition in $vpartitions; do
		#mount $filesystem /mnt/non_gnu
		#if [ `find /mnt/non_gnu/Windows -name kernel32.exe` != "" ];then
		    IDJ=`echo $partition | cut -d "/" -f 3`
		    echo "# Detected NON-FREE OS $IDJ" >> $LILOCONF
		    echo "other=$partition" >> $LILOCONF
		    echo "       label=NONFREEOS-$IDJ" >> $LILOCONF
		    echo "" >> $LILOCONF
		#fi
		#umount /mnt/non_gnu

		case $partition in
		/dev/sda1 )
		    BUSGRUB="0"
		    HDDGRUB="0"
		    ;;
		/dev/sda2 )
		    BUSGRUB="0"
		    HDDGRUB="1"
		    ;;
		/dev/sda3 )
		    BUSGRUB="0"
		    HDDGRUB="2"
		    ;;
		/dev/sda4 )
		    BUSGRUB="0"
		    HDDGRUB="3"
		    ;;
		/dev/sdb1 )
		    BUSGRUB="1"
		    HDDGRUB="0"
		    ;;
		/dev/sdb2 )
		    BUSGRUB="1"
		    HDDGRUB="1"
		    ;;
		/dev/sdb3 )
		    BUSGRUB="1"
		    HDDGRUB="2"
		    ;;
		/dev/sdb4 )
		    BUSGRUB="1"
		    HDDGRUB="3"
		    ;;
		/dev/sdc1 )
		    BUSGRUB="2"
		    HDDGRUB="0"
		    ;;
		/dev/sdc2 )
		    BUSGRUB="2"
		    HDDGRUB="1"
		    ;;
		/dev/sdc3 )
		    BUSGRUB="2"
		    HDDGRUB="2"
		    ;;
		/dev/sdc4 )
		    BUSGRUB="2"
		    HDDGRUB="3"
		    ;;
		/dev/sdd1 )
		    BUSGRUB="3"
		    HDDGRUB="0"
		    ;;
		/dev/sdd2 )
		    BUSGRUB="3"
		    HDDGRUB="1"
		    ;;
		/dev/sdd3 )
		    BUSGRUB="3"
		    HDDGRUB="2"
		    ;;
		/dev/sdd4 )
		    BUSGRUB="3"
		    HDDGRUB="3"
		    ;;
		esac
		
		echo " " >> $GRUBCONF
		echo "title NONFREEOS-$IDJ " >> $GRUBCONF
		echo "map (hd0,0) (hd$BUSGRUB,$HDDGRUB) " >> $GRUBCONF
		echo "map (hd$BUSGRUB,$HDDGRUB) (hd0,0) " >> $GRUBCONF
		echo "rootnoverify (hd$BUSGRUB,$HDDGRUB) " >> $GRUBCONF
		echo "chainloader +1" >> $GRUBCONF

		++j
	done
	rmdir /mnt/non_gnu

	local -a lpartitions
	local ii=0
	local jj=1
	OTHER_GNU=`LANGUAGE="en" sfdisk -l | grep Linux | grep -v "swap" | awk -F \  /Linux/'{print $1}'`
	mkdir /mnt/other_gnu
	for filesystem in $OTHER_GNU; do
		mount $filesystem /mnt/other_gnu
		#cat /mnt/other_gnu/etc/lilo.conf | grep -v "#" | grep -v "default=" | grep -v map | grep -v install | grep -v prompt | grep -v nowarn | grep -v timeout= | grep -v lba | grep -v vga= | grep -v boot= | grep -v bmp >> $LILOCONF
		cp /mnt/other_gnu/etc/lilo.conf $LILOCONF-`echo $filesystem | sed "s/\//-/g"`
		cp /mnt/other_gnu/boot/grub/grub.conf $GRUBCONF-grub.conf-`echo $filesystem | sed "s/\//-/g"`
		cp /mnt/other_gnu/boot/grub/menu.lst $GRUBCONF-menu.lst-`echo $filesystem | sed "s/\//-/g"`
		cp /mnt/other_gnu/boot/grub/grub.lst $GRUBCONF-grub.lst-`echo $filesystem | sed "s/\//-/g"`
		umount /mnt/other_gnu
	done

	return 0
}

function crearFstab() {

	particionswapprevia=$1

	FORMATOPORDEFECTOREAL=`mount | grep "/dev/$PARTICIONROOT" | cut -d " " -f 5`
	cp ./fstab.$STAGEAINSTALAR /mnt/$PARTICIONROOT/etc/
	mv /mnt/$PARTICIONROOT/etc/fstab.$STAGEAINSTALAR /mnt/$PARTICIONROOT/etc/fstab
	sed -i "s/ROOT/$PARTICIONROOT/" /mnt/$PARTICIONROOT/etc/fstab
	sed -i "s/FORMATOPORDEFECTO/$FORMATOPORDEFECTOREAL/" /mnt/$PARTICIONROOT/etc/fstab
	DEVICESWAPFSTAB=$(sfdisk -d | grep 'Id=82' | awk '{print $1}' | head -n 1 | cut -d '/' -f 3)
	if [ "$DEVICESWAPFSTAB" = "" ];then
	    sed -i "s/SWAP/\/swap/" /mnt/$PARTICIONROOT/etc/fstab
	else
	    sed -i "s/SWAP/\/dev\/$DEVICESWAPFSTAB/" /mnt/$PARTICIONROOT/etc/fstab
	fi

	#if [ "x$particionswapprevia" != "x" ]; then
	#	#sed -i 's@^/SWAP@'$particionswapprevia'@' /mnt/$PARTICIONROOT/etc/fstab
	#	sed -i "s/\/SWAP/$particionswapprevia/" /mnt/$PARTICIONROOT/etc/fstab
	#fi
	return 0
}

function instalarStage() {
	local FILE="$1"
	local N_FILES="$2"
	local FILE_STEP=$(( $N_FILES / 10 ))
	local STEPPING=1
	local i=0
	local j=$3
	local INSTALL_PATH=$4
	local TITULO
	local DESCRIPCION
	
	[ "$5" = "" ] && TITULO="Installing ${FILE/*\/}" || TITULO=$5
	[ "$6" = "" ] && DESCRIPCION="Installing ${FILE/*\/}" || DESCRIPCION=$6
	
	progresoInstalacion $j "$TITULO" "$DESCRIPCION"

	if [ $(echo $FILE | grep ".*.7z$" | wc -l) -eq 1 ]; then
		$DIRBASE/bin/runasroot.sh "/usr/bin/7za x -bd -so $FILE 2>/tmp/instalar.log | tar xvf - -C $INSTALL_PATH 2>/tmp/instalar.log |"
		while read f; do
			i=$(( i + 1 ))
			if let "( $i % $FILE_STEP ) == 0"; then
				j=$(( j + STEPPING ))
				progresoInstalacion $j "$TITULO" "$DESCRIPCION"
			fi
		done
	else
		$DIRBASE/bin/runasroot.sh "/bin/tar xvf $FILE -C $INSTALL_PATH 2>/tmp/instalar.log |"
		while read f; do
			i=$(( i + 1 ))
			if let "( $i % $FILE_STEP ) == 0"; then
				j=$(( j + STEPPING ))
				progresoInstalacion $j "$TITULO" "$DESCRIPCION"
			fi
		done
	fi
	
	return 0
}

function formatearDiscoCompleto()
{
	local disco="$1"
	local P

	# Verifica si el parámetro recibido es un disco
	if [ "$(awk '/'$disco'$/ { print $4 }' /proc/partitions)" != "$disco" -o ! -b /dev/$disco ]; then
		echo "formatearDiscoCompleto: Error [$disco] no es un dispositivo de bloques listado en /proc/partitions"
		return 1
	fi
	
	# Crea una etiqueta compatible msdos
	parted /dev/$disco mklabel msdos
	
	# Elimina todas las particiones
	echo "formatearDiscoCompleto: Se eliminaran las particiones en $disco: $(awk '/'$disco'[0-9]+$/ { print $2 }' /proc/partitions)"
	for P in $(awk '/'$disco'[0-9]+$/ { print $2 }' /proc/partitions);
	do
		echo "formatearDiscoCompleto: Eliminando particion ${disco}$P"
		parted /dev/$disco rm $P
	done
	if [ $(grep -c $disco /proc/partitions) -ne 1 ]; then
		echo "formatearDiscoCompleto: Error eliminando particiones del disco $disco"
		return 1
	fi
	
	# Crea una partición ocupando todo el disco
	parted /dev/$disco mkpart primary 0 $(( $(sfdisk -s /dev/$disco) / 1024 ))
	sync
	for ((i=0; i<10; i++));
	do
		[ -b /dev/${disco}1 ] && break
		sleep 1
	done
	
	# Verifica que la partición se haya creado
	if [ $(awk '/'$disco'[0-9]+$/ { print $2 }' /proc/partitions | wc -l) -ne 1 -o ! -b "/dev/${disco}1" ]; then
		echo "formatearDiscoCompleto: Error al crear particion en $disco"
		return 1
	fi
	
	return 0
}

