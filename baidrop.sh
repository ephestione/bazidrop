#!/bin/bash

BNAME=$(uname -n)
BDATE=$(date +%Y-%m-%d)
BMODE=cyclic

# all foldernames must end with /
BSOURCE=/home/yourhomefolder/
BDEST=/mnt/whatever
BWORK=/tmp/
BUSR=yourusername

DBUSER=dbuser
DBPASS=dbpass
DBNAME=dbname

DBUPLOADER=/path/to/dropbox_uploader.sh

CRYPTPSW=encryptionpassword

if [ $1 ]
 then
  if [ $1 == "latest" ]
    then
        BMODE=latest
  fi
fi

rsync -a ${BSOURCE} ${BDEST}${BUSR} --delete #remove --delete if you want to keep deleted files in the source
rsync -a --del --exclude admin/ /var/www/ ${BDEST}www  #see above
mysqldump -u${DBUSER} -p${DBPASS} ${DBNAME} | bzip2 > ${BDEST}mysqldump.bz2
crontab -u ${BUSR} -l > ${BDEST}crontab-${BUSR}.txt
crontab -l > ${BDEST}crontab-root.txt
cp /etc/apache2/sites-enabled/000-default.conf ${BDEST}
cp /etc/rc.local ${BDEST}

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

