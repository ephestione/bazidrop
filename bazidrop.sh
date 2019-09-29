#!/bin/bash

# ========== CONFIG ==========
# all foldernames must end with /
BSOURCE=/home/yourhomefolder/
BDEST=/mnt/whatever
BWORK=/tmp/
BUSR=yourusername

DBUSER=dbuser
DBPASS=dbpass
DBNAME=dbname

# EXCLUDES= "--exclude somefolder/" # check rsync manpage

DBUPLOADER=/path/to/dropbox_uploader.sh

CRYPTPSW=encryptionpassword
# ========= /CONFIG ==========

BNAME=$(uname -n)
BDATE=$(date +%Y-%m-%d)
BMODE=cyclic

# following is useful if you want to create a bazidrop.sh.cfg file in the same folder of this script
# contents of the file should be the variable definitions above with the correct values
# so the config is loaded from there and in case of updates you can just do
# curl "https://raw.githubusercontent.com/ephestione/bazidrop/master/bazidrop.sh" -o bazidrop.sh
# otherwise just edit above and leave it alone, it will throw an unconsequential error but who cares right?
cd "${0%/*}"
. bazidrop.sh.cfg

if [ $1 ]
 then
  if [ $1 == "latest" ]
    then
        BMODE=latest
  fi
fi

mkdir -p ${BDEST}home/${BUSR}
mkdir -p ${BDEST}var/www
mkdir -p ${BDEST}etc
mkdir -p ${BDEST}boot

rsync -a --delete --force --delete-excluded ${EXCLUDES} ${BSOURCE} ${BDEST}home/${BUSR} #remove --delete if you want to keep deleted files in $BDEST
rsync -a --delete --force --delete-excluded --exclude admin/ /var/www/ ${BDEST}/var/www  #see above
rsync -a --delete --force --delete-excluded --exclude '*pihole*' /etc/ ${BDEST}etc/
mysqldump -u${DBUSER} -p${DBPASS} ${DBNAME} | bzip2 > ${BDEST}mysqldump.bz2
crontab -u ${BUSR} -l > ${BDEST}crontab-${BUSR}.txt
crontab -l > ${BDEST}crontab-root.txt
cp /boot/config.txt ${BDEST}boot/

# restore following with:
# sudo xargs -a packages_list.txt apt install
dpkg-query -f '${binary:Package}\n' -W > ${BDEST}packages_list.txt


FILENAME=${BNAME}-${BMODE}

7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ${BWORK}${FILENAME}.7z ${BDEST}
echo "${CRYPTPSW}" | gpg --batch --yes --passphrase-fd 0 -c -o ${BWORK}${FILENAME}.7z.gpg ${BWORK}${FILENAME}.7z

if [ ${BMODE} == "cyclic" ]
  then
      ${DBUPLOADER} delete ${FILENAME}.3.7z.gpg
      ${DBUPLOADER} move ${FILENAME}.2.7z.gpg ${FILENAME}.3.7z.gpg
      ${DBUPLOADER} move ${FILENAME}.1.7z.gpg ${FILENAME}.2.7z.gpg
      ${DBUPLOADER} move ${FILENAME}.7z.gpg ${FILENAME}.1.7z.gpg
fi


${DBUPLOADER} upload ${BWORK}${FILENAME}.7z.gpg .
rm ${BWORK}${FILENAME}*
