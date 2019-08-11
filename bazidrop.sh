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

rsync -a --delete --force --delete-excluded ${EXCLUDES} ${BSOURCE} ${BDEST}${BUSR} #remove --delete if you want to keep deleted files in $BDEST
rsync -a --delete --force --delete-excluded --exclude admin/ /var/www/ ${BDEST}www  #see above
mysqldump -u${DBUSER} -p${DBPASS} ${DBNAME} | bzip2 > ${BDEST}mysqldump.bz2
crontab -u ${BUSR} -l > ${BDEST}crontab-${BUSR}.txt
crontab -l > ${BDEST}crontab-root.txt
cp /etc/apache2/sites-enabled/000-default.conf ${BDEST}
cp /etc/rc.local ${BDEST}
cp /etc/fstab ${BDEST}

FILENAME=${BNAME}-${BMODE}

tar -vczf ${BWORK}${FILENAME}.gz ${BDEST}
echo "${CRYPTPSW}" | gpg --batch --yes --passphrase-fd 0 -c -o ${BWORK}${FILENAME}.gz.gpg ${BWORK}${FILENAME}.gz

if [ ${BMODE} == "cyclic" ]
  then
      ${DBUPLOADER} delete ${FILENAME}.3.gz.gpg
      ${DBUPLOADER} move ${FILENAME}.2.gz.gpg ${FILENAME}.3.gz.gpg
      ${DBUPLOADER} move ${FILENAME}.1.gz.gpg ${FILENAME}.2.gz.gpg
      ${DBUPLOADER} move ${FILENAME}.gz.gpg ${FILENAME}.1.gz.gpg
fi


${DBUPLOADER} upload ${BWORK}${FILENAME}.gz.gpg .
rm ${BWORK}${FILENAME}*
