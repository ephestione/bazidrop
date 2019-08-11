# BaZiDrop

*Ba*ckup, *Zi*p and *Drop*box

I do use https://github.com/lzkelley/bkup_rpimage already to image my OS on an external drive, but what if the room explodes and I'm left with nothing?
I need to at least backup only the important files, in a small enough package to upload to the cloud, in this case Dropbox.
So this script also needs https://github.com/andreafabrizi/Dropbox-Uploader

Basically you need to edit everything at the beginning of the script, removing what you don't need and adding what you do need.
The script rsyncs the home folder and /var/www/, saves a mysql dump, the root and user crontab and the apache2 sites configuration, which were functional in my case.

Then it gzips everything, encrypts it with GPG, and uploads to dropbox, after which gzip and gpg encrypted files are removed (not the rsync'd folders because I want to keep them)

I know the code looks ugly, I am a bash initiate. It works though, and if you like please suggest/add edits.

There are two methods:

- Default: "cyclic" mode, just run the command with root privileges as it is, it is hardcoded in 4 versions, and filenames are like those in logrotate: backup.3 is deleted, backup.2 becomes backup.3, backup.1 becomes backup.2, backup becomes backup.1, and finally the latest backup is uploaded; the dropbox script will throw an exception for the first runs, as the old backups don't exist yet, but they are non-blocking errors so I didn't bother implementing checks.
- Latest: a backup-latest file is created and uploaded, overwriting existing file on dropbox.

I have both methods running in crontab, the cyclic goes once each 3 days, an the latest every few hours.

This should be used with most distributions actually, I just need it for my RasPi's and that's what it was created for.

# Instructions
- install and configure https://github.com/andreafabrizi/Dropbox-Uploader
- curl "https://raw.githubusercontent.com/ephestione/bazidrop/master/bazidrop.sh" -o bazidrop.sh
- either edit the first lines of the script, or create a bazidrop.sh.cfg file in the script's folder, containing those lines edited to suit you
- chmod +x bazidrop.sh
- run the script as root, either as is (cyclic mode) or with the "latest" parameter, so upload/overwrite the latest system shot
