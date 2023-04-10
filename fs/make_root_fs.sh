# Settings !!!*** PLEASE MODIFY THESE ***!!!
export TTTDIR=`pwd`"/tmp"

# Making the filesystem
fallocate -l 500000000 root_fs
mkfs -F -t ext4 root_fs
mkdir -p $TTTDIR
mount -o loop root_fs $TTTDIR

# debootstrap
debootstrap --include vim,sysvinit-core,less,netcat,python3,python3-pip,strace,net-tools buster $TTTDIR http://ftp.us.debian.org/debian/

# setup resolver
cp /etc/resolv.conf $TTTDIR/etc/
cp $TTTDIR/usr/share/sysvinit/inittab $TTTDIR/etc/inittab

# fstab
#cp fstab $TTTDIR/etc

# tweak the inittab to only use tty0 and add it to securetty
cp $TTTDIR/etc/inittab $TTTDIR/etc/inittab.save
grep -v "getty" $TTTDIR/etc/inittab.save > $TTTDIR/etc/inittab
echo "# We launch just one console for UML:" >> $TTTDIR/etc/inittab
echo "c0:1235:respawn:/sbin/getty 38400 tty0 linux" >> $TTTDIR/etc/inittab
echo "# Launch 2 xterms" >> $TTTDIR/etc/inittab
echo "1:2345:respawn:/sbin/getty 38400 tty1"  >> $TTTDIR/etc/inittab
echo "2:23:respawn:/sbin/getty 38400 tty2"  >> $TTTDIR/etc/inittab

echo "# UML modification: use tty0 or vc/0" >> $TTTDIR/etc/securetty
echo "tty0" >> $TTTDIR/etc/securetty
echo "vc/0" >> $TTTDIR/etc/securetty

#set hostname
echo "host" >  $TTTDIR/etc/hostname

#remove password
sed -i 's/root:\*:/root::/g' $TTTDIR/etc/shadow


cat <<EOT >> $TTTDIR/etc/motd
The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

 _______________________
     < Welcome! >
 -----------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/
                ||----w |
                ||     ||
EOT

umount $TTTDIR
rmdir $TTTDIR

