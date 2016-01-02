from datetime import datetime
import logging
import os
import shutil
import socket
import subprocess
import sys
import tarfile
import tempfile

from boto.exception import S3ResponseError
from boto.s3.bucket import Bucket
from boto.s3.connection import S3Connection
from boto.s3.key import Key

from app.config import get_path
import app.database
import cli


class RestoreCli(cli.BaseCli):
    ''' Restore database and data directory from a backup file. '''

    def _confirm(self):
        ''' Print an ominous warning message. '''

        message = [
            'This script will overwrite all files in the /data/ directory',
            'and will drop the database. This operation can NOT be undone.',
        ]

        print('*' * 80)

        for line in message:
            print('* {: <76} *'.format(line))

        print('*' * 80)
        print()

        response = ''

        while response.lower() not in ('yes', 'no'):
            sys.stdout.write('Continue? (yes/no) ')
            sys.stdout.flush()
            response = sys.stdin.readline().strip()

        return response.lower() == 'yes'

    def _load_mysql(self, file_):
        ''' Load MySQL database from an open file object. '''


        # Drop and re-create database.
        msg = 'Dropping database "{}"' .format(self._db_config['database'])
        self._logger.info(msg)
        env = {'MYSQL_PWD': self._db_config['super_password']}

        drop_args = [
            'mysql',
            '-u',
            self._db_config['super_username'],
            self._db_config['database'],
        ]

        drop = subprocess.Popen(
            drop_args,
            env=env,
            stdin=subprocess.PIPE,
            stdout=None,
            stderr=None
        )

        command = 'DROP DATABASE {0}; CREATE DATABASE {0};' \
                  .format(self._db_config['database']) \
                  .encode('ascii')

        drop.communicate(input=command)

        if drop.returncode != 0:
            raise BackupError('Failed to load MySQL database!')

        # Load from backup file.
        msg = 'Loading database "{}"' .format(self._db_config['database'])
        self._logger.info(msg)

        load_args = [
            'mysql',
            '-u',
            self._db_config['super_username'],
            self._db_config['database'],
        ]

        load = subprocess.Popen(
            load_args,
            env=env,
            stdin=file_,
            stdout=None,
            stderr=None
        )

        load.wait()

        if load.returncode != 0:
            raise BackupError('Failed to load MySQL database!')

    def _get_args(self, arg_parser):
        ''' Customize arguments. '''

        arg_parser.add_argument(
            'action',
            choices=('list','load'),
            help='Specify what action to take.'
        )

        arg_parser.add_argument(
            's3file',
            nargs='?',
            help='Name of backup file to load from S3 (required for "load"' \
                 ' action).'
        )

        arg_parser.add_argument(
            '--yes',
            action='store_true',
            help='Assume "yes" to all questions.'
        )

    def _restore(self, bucket, s3file):
        ''' Restore file `s3file` from `bucket`. '''

        root_dir = app.config.get_path()
        data_dir = app.config.get_path('data')
        mysql_path = os.path.join(data_dir, 'backup.sql')

        try:
            with tempfile.NamedTemporaryFile('wb+') as tar_temp:

                self._logger.info('Fetching "{}" from S3.'
                                  .format(s3file))
                s3_file = Key(bucket)
                s3_file.key = s3file

                try:
                    s3_file.get_contents_to_file(tar_temp)
                except S3ResponseError as e:
                    if e.status == 404:
                        raise cli.CliError('File not found on S3.')
                    else:
                        raise

                tar_temp.seek(0)

                with tarfile.open(fileobj=tar_temp, mode='r:gz') as tarball:
                    for name in tarball.getnames():
                        if name[:4] != 'data':
                            msg = 'Invalid tarball; it contains directory' \
                                  ' entries other than "data/".'
                            raise cli.CliError(msg)

                    self._logger.info('Removing existing data/ directory.')
                    shutil.rmtree(data_dir)

                    self._logger.info('Extracting data/ directory from backup.')
                    os.chdir(root_dir)
                    tarball.extractall()

                    with open(mysql_path, 'r') as mysql_backup:
                        self._load_mysql(mysql_backup)
        finally:
            try:
                os.unlink(mysql_path)
            except:
                pass


    def _run(self, args, config):
        ''' Main entry point. '''

        self._db_config = dict(config.items('database'))
        aws_config = dict(config.items('aws'))

        self._logger.info('Connecting to S3...')
        s3_debug = 2 if self._logger.level == logging.DEBUG else 0

        s3 = S3Connection(
            aws_config['access_key'],
            aws_config['secret_key'],
            debug=s3_debug
        )

        bucket = Bucket(connection=s3, name=aws_config['backup_bucket'])

        if args.action == 'list':
            self._logger.info('Listing available files...')
            for s3_file in bucket.list():
                print(' * {}'.format(s3_file.key))
        elif args.action == 'load':
            if not args.yes and not self._confirm():
                raise cli.CliError('Canceled by user.')

            if args.s3file is None:
                raise cli.CliError('File name is required')

            self._restore(bucket, args.s3file)

        self._logger.info('Finished.')
