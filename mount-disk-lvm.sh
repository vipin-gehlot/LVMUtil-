#!/bin/bash

set -e

# To scan the disks
echo "- - -" >/sys/class/scsi_host/host0/scan
echo "- - -" >/sys/class/scsi_host/host1/scan
echo "- - -" >/sys/class/scsi_host/host2/scan

# to check disk is avvailable or not

lsblk
echo ----------------------------------------------
lsblk | grep 50G | grep disk
disk_info=$(lsblk | grep 50G | grep disk)
disk_name=/dev/$( echo $disk_info | awk '{print $1}')
if [ -z disk_name ]; then
        echo "No new disk of 50GB found"
        exit 1
fi

echo Is it correct disk : $disk_name ? [y/n]
read var_option
if [ $var_option == "y" ]; then

        # to create PV
        echo "Creating Physical Volumn : $disk_name "
        if [ $(pvs | grep $disk_name | wc -l) == 0 ]; then
                pvcreate $disk_name
        else
                echo "##################################################"
                echo "## $disk_name : Physical Volumn already exists"
                echo "##################################################"
        fi
        #to check pv created or nor
        pvs
        echo Done.
        echo  ------------------------------------------
        echo "Creating Volume Group : vg02"

        #To create Volume Group
        if [ $(vgs | grep vg02 | wc -l) == 0 ]; then
                vgcreate vg02 $disk_name
        else
                echo "###############################################"
                echo "## vg02 : Volume Group already exists"
                echo "###############################################"
        fi
        # To check Volume Group
        vgs

        echo Done.
        echo  ------------------------------------------
        echo "Creating Logical Volume : "
        # To create Logical Volume
        if [ $(lvs | grep lv_tomcat | wc -l) == 0 ]; then
                #lvcreate -L <size> -n <lvname> <vgname>
                lvcreate -l 100%VG -n lv_tomcat vg02
        else
                echo "###############################################"
                echo "## lv_tomcat : Logical Volume already exists."
                echo "###############################################"
        fi
        lvs

        # install ext4 filesystem
        echo "Formatting /dev/vg02/lv_tomcat, Continue ? [y/n] "
        read option_format
        if [ $option_format == 'y' ]; then
                mkfs.ext4 /dev/vg02/lv_tomcat
                echo Done.
                echo  ------------------------------------------
        else
                echo "Exiting Process."
                exit 1
        fi
        # create mount ponit
        mkdir -p /opt/tomcat-server
        # add entries in /etc/fstab
        echo "Do you want add /etc/fstab entry ? : [y/n]"
        read var_fstab
        if [ $var_fstab == 'y' ]; then

                echo "/dev/mapper/vg02-lv_tomcat      /opt/tomcat-server      ext4    defaults        0       0" >> /etc/fstab
        fi

        #mount filesytem
        echo "Mounting new patition on /opt/tomcat-server"
        mount /dev/mapper/vg02-lv_tomcat /opt/tomcat-server
        chown -R wasadm:wasgrp /opt/tomcat-server
        echo "All Good, Enjoy."
        read -s -n 1 -p "Press any key to continue..."
        df -h
else
        echo "Exit the process, Good Bye! "
fi
