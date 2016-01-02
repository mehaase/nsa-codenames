from datetime import datetime
import logging
import os
import socket
import subprocess
import sys
import tarfile
import tempfile

from boto.s3.bucket import Bucket
from boto.s3.connection import S3Connection
from boto.s3.key import Key

from app.config import get_path
import app.database
import cli


class BackupCli(cli.BaseCli):
    ''' Backup database and data directory. '''

    def _dump_mysql(self, config, file_):
        ''' Dump MySQL database to an open file object. '''

        mysqldump_args = [
            'mysqldump',
            '-u',
            config['super_username'],
            config['database'],
        ]

        mysqldump = subprocess.Popen(
            mysqldump_args,
            env={'MYSQL_PWD': config['super_password']},
            stdout=file_
        )

        mysqldump.wait()

        if mysqldump.returncode != 0:
            raise cli.CliError('Failed to dump MySQL database!')


    def _run(self, args, config):
        ''' Main entry point. '''

        db_config = dict(config.items('database'))
        aws_config = dict(config.items('aws'))
        hostname = socket.gethostname()
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        s3_path = '{}.{}.tgz'.format(hostname, timestamp)
        data_dir = get_path('data')
        mysql_path = os.path.join(data_dir, 'backup.sql')

        self._logger.info('Connecting to S3...')
        s3_debug = 2 if self._logger.level == logging.DEBUG else 0

        s3 = S3Connection(
            aws_config['access_key'],
            aws_config['secret_key'],
            debug=s3_debug
        )

        bucket = Bucket(connection=s3, name=aws_config['backup_bucket'])

        try:
            with open(mysql_path, 'w+') as mysql_backup:
                msg = 'Dumping database "{}" to {}'
                self._logger.info(msg.format(db_config['database'], data_dir))
                self._dump_mysql(db_config, mysql_backup)

            with tempfile.NamedTemporaryFile('wb+') as tar_temp, \
                 tarfile.open(fileobj=tar_temp, mode='w:gz') as tarball:

                self._logger.info('Backing up {}'.format(data_dir))
                tarball.add(data_dir, arcname='data')
                tarball.close()
                tar_temp.flush()
                tar_temp.seek(0)

                self._logger.info('Saving "{}" to S3.'.format(s3_path))
                s3_file = Key(bucket)
                s3_file.key = s3_path
                headers = {'Content-Type': 'application/x-gzip'}
                s3_file.set_contents_from_file(tar_temp, headers=headers)

        finally:
            try:
                os.unlink(mysql_path)
            except:
                pass

        self._logger.info('Finished.')
