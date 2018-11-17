#!/bin/bash

CK=`uname -r |sed 's/.rs//'|sed  's/.el7.x86_64//'`
echo $#
if [ $# -eq 1 ]
then
    KBV=$1
else
    KBV=$CK
fi


function download {
echo "Looking to download $KF"

x=`curl http://vault.centos.org/ 2>/dev/null|grep -o '7\.[0-9]\{1,2\}\.[0-9]\{1,6\}' |sort -u`
for word in $x 
do
    for src in os updates
    do
        u="Trying http://vault.centos.org/$word/$src/Source/SPackages/"
	echo $u
        if ( curl -v $u  2>/dev/null|grep $KF -o >/dev/null)
        then
    	    echo "Found, downloading ..."
    	    wget http://vault.centos.org/$word/$src/Source/SPackages/$KF -O $KF
    	    if ( rpm -K $KF >/dev/null 2>/dev/null  )
    	    then 
    		echo /home/$BUSER/$KF signature ok
    		cp $KF /home/$BUSER/$KF
    		break 2
    	    else 
    		echo You have a bad rpm, retry downloading, or manually download the file and put it in the current directory
    		exit
    	    fi
	fi
    done
done

}
#the username used to build the kernel, will be in /home/kbuild by default
BUSER=kbuild
#the current centos version release
cver=`cat /etc/centos-release |cut -f 4 -d " "`
echo "OS Build $cver"


#delete all the previous build data files
echo "Removing old build directory"
userdel -r $BUSER >/dev/null 2>&1
groupdel $BUSER >/dev/null 2>&1
useradd ${BUSER}

#current running kernel

echo "Trying to build for kernel $KBV"
KF="kernel-$KBV.el7.src.rpm"

if [ -f $KF ]
then
    echo $KF found in current directory, checking signature ...
    if ( rpm -K $KF >/dev/null 2>/dev/null  )
    then
	echo "$KF signature ok"
	cp $KF /home/$BUSER/$KF
    else
	echo $KF corrupted, re-downloading
	download
    fi
else 
    download
fi

if [ ! -f /home/${BUSER}/$KF ]
then
    echo "Couldn't download rpm"
    exit
fi
chown ${BUSER}:${BUSER} /home/${BUSER}/$KF
sudo -u ${BUSER} rpm -i /home/${BUSER}/$KF
cat toa-patch-linux-3.10.0-327.28.3.el7.patch | sed "s/3.10.0-327.28.3/${KBV}/g"  > /home/${BUSER}/rpmbuild/SOURCES/toa-patch-linux-$KBV.el7.patch
chown ${BUSER}.${BUSER} /home/${BUSER}/rpmbuild/SOURCES/toa-patch-linux-$KBV.el7.patch







toa=toa-patch-linux-${KBV}.el7.patch


cd /home/${BUSER}/rpmbuild/SOURCES

IFS='
'
for l in `ls *.config|grep -v kernel-3.10.0-x86_64.config `; do echo '#CONFIG_TOA is not set'  >> $l; done
rm -f kernel-3.10.0-x86_64-debug.config
echo "CONFIG_TOA=m" >> kernel-3.10.0-x86_64.config




cd /home/${BUSER}/rpmbuild/SPECS
sed -i -e "s/linux-kernel-test.patch/toa-patch-linux-${KBV}.el7.patch/g" kernel.spec
sed -i -e 's/# % define buildid .local/%define buildid .rs/g' kernel.spec
cat kernel.spec |grep -v 'x86_64-debug.config' > tmp
mv tmp kernel.spec


chown ${BUSER}:${BUSER} /home/${BUSER} -R

sudo -u ${BUSER} rpmbuild -ba --without kabichk --without debuginfo --without debug --without xen --with firmware --target=`uname -m` /home/${BUSER}/rpmbuild/SPECS/kernel.spec





exit



echo "Getting last kernel src version"
wget "http://vault.centos.org/${cver}/updates/Source/SPackages/?C=M;O=A" -O src.tmp -o /dev/null
src=`cat src.tmp |grep kernel |tail -1  |grep -o 'kernel-3.10.0-[1-9\.]\{1,20\}\.el7\.src\.rpm' |head -1`
rm -f src.tmp
echo "Latest version is $src"
wget "http://vault.centos.org/${cver}/updates/Source/SPackages/$src" -O $src
useradd ${BUSER}
mv ${src} /home/${BUSER}
chown ${BUSER}:${BUSER} /home/${BUSER}/${src}
sudo -u ${BUSER} rpm -i /home/${BUSER}/${src}
version=`echo $src| sed  's/kernel-//g' |sed 's/.el7.src.rpm//g'`
toa=toa-patch-linux-${version}.el7.patch


cd /home/${BUSER}/rpmbuild/SOURCES

IFS='
'
for l in `ls *.config|grep -v kernel-3.10.0-x86_64.config `; do echo '#CONFIG_TOA is not set'  >> $l; done
rm -f kernel-3.10.0-x86_64-debug.config
echo "CONFIG_TOA=m" >> kernel-3.10.0-x86_64.config




cd /home/${BUSER}/rpmbuild/SPECS
sed -i -e "s/linux-kernel-test.patch/toa-patch-linux-${version}.el7.patch/g" kernel.spec
sed -i -e 's/# % define buildid .local/%define buildid .rs/g' kernel.spec
cat kernel.spec |grep -v 'x86_64-debug.config' > tmp
mv tmp kernel.spec


chown ${BUSER}:${BUSER} /home/${BUSER} -R

sudo -u ${BUSER} rpmbuild -ba --without kabichk --without debuginfo --without debug --without xen --with firmware --target=`uname -m` /home/${BUSER}/rpmbuild/SPECS/kernel.spec




#echo export src=$src
#echo export version=$version
#echo export toa=$toa

