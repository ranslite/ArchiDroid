#!/bin/bash
# ArchiDroid build.sh Helper

# Not Disabled
#exit 1

# Common
VERSION=1.7
MODE=0 # 0 - Experimental | 1 - Stable

# From source? Nope!
SOURCE=0

OTA="echo \"updateme.version=$VERSION\" >> /system/build.prop"
if [ $MODE -eq 0 ]; then
	VERSION="$VERSION EXPERIMENTAL"
else
	VERSION="$VERSION STABLE"
fi

function zamien {
	FILEO=wynik.txt
	# $1 co
	# $2 na co
	# $3 plik
	GDZIE=`grep -n "${1}" $3 | cut -f1 -d:`
	ILE=`cat $3 | wc -l`
	ILE=`expr $ILE - $GDZIE`
	GDZIE=`expr $GDZIE - 1`
	cat $3 | head -${GDZIE} > $FILEO
	echo $2 >> $FILEO
	cat $3 | tail -${ILE} >> $FILEO
	cp $FILEO $3
	rm $FILEO
}

if [ $SOURCE -eq 1 ]; then
	cd /root/shared/git/auto
	bash updaterepos.sh
	cd /root/android/system/out/target/product/i9300
	if [ $? -eq 0 ]; then
		for f in `ls` ; do
		if [[ "$f" != "obj" ]]; then
			rm -rf $f
		fi
	done
  fi
  cd /root/android/system
	OLD=`md5sum /root/android/system/device/samsung/i9300/proprietary-files.txt | awk '{print $1}'`
	OLD2=`md5sum /root/android/system/device/samsung/smdk4412-common/proprietary-files.txt | awk '{print $1}'`
	#repo selfupdate
	repo sync
	if [ $? -ne 0 ]; then
		read -p "Something went wrong, please check and tell me when you're done, master!" -n1 -s
	fi
	cd /root/android/system/vendor/cm
	./get-prebuilts
	cd /root/android/system
	source build/envsetup.sh
	breakfast i9300
	NEW=`md5sum /root/android/system/device/samsung/i9300/proprietary-files.txt | awk '{print $1}'`
	NEW2=`md5sum /root/android/system/device/samsung/smdk4412-common/proprietary-files.txt | awk '{print $1}'`
	if [ $OLD != $NEW ] || [ $OLD2 != $NEW2 ]; then
		echo "/root/android/system/device/samsung/i9300/proprietary-files.txt" $OLD $NEW
		echo "/root/android/system/device/samsung/smdk4412-common/proprietary-files.txt" $OLD2 $NEW2
		read -p "Something went wrong, please check and tell me when you're done, master!" -n1 -s
	fi
	brunch i9300
	cd $OUT
	cp cm-10.2-*.zip /root/shared/git/ArchiDroid
fi

##################
### OTA UPDATE ###
FILE=otaold.sh
FILEO=ota.sh
cp ../_archidroid/ota/ota.sh $FILE
GDZIE=`grep -n "updateme.version=" $FILE | cut -f1 -d:`
ILE=`cat $FILE | wc -l`
ILE=`expr $ILE - $GDZIE`
GDZIE=`expr $GDZIE - 1`
cat $FILE | head -${GDZIE} > $FILEO
echo $OTA >> $FILEO
ILE=`expr $ILE + 1`
cat $FILE | tail -${ILE} >> $FILEO
cp $FILEO $FILE
rm $FILEO
cp $FILE ../_archidroid/ota/ota.sh
rm $FILE
### OTA UPDATE ###
##################

#########################
### BUILD.PROP UPDATE ###
FILE=buildold.prop
FILEO=build.prop
cp ../system/build.prop $FILE

echo "# ArchiDroid build.prop" >> $FILEO
cat $FILE >> $FILEO
cp $FILEO $FILE
rm $FILEO

sed -i 's/ro.sf.lcd_density=320/#ro.sf.lcd_density=320/g' ../system/build.prop

GDZIE=`grep -n "ro.build.display.id=" $FILE | cut -f1 -d:`
ILE=`cat $FILE | wc -l`
ILE=`expr $ILE - $GDZIE`
GDZIE=`expr $GDZIE - 1`
cat $FILE | head -${GDZIE} > $FILEO
echo "ro.build.display.id=ArchiDroid $VERSION" >> $FILEO
echo "ro.archidroid.version=$VERSION" >> $FILEO
cat $FILE | tail -${ILE} >> $FILEO
cp $FILEO $FILE
rm $FILEO

cp $FILE ../system/build.prop
rm $FILE

### BUILD.PROP UPDATE ###
#########################

#################
### BLOATWARE ###
#rm -f ../system/app/CMUpdater.apk
### BLOATWARE ###
#################

cd framework-res
zip -0 -r ../../system/framework/framework-res.apk *
cd ..

bash openpdroid.sh
if [ $? -ne 0 ]; then
	exit 1
else
	exit 0
fi
