import configparser
import os

"""
Read the application configuration from the standard configuration files.
"""
def get_config():
    config_files = [
        os.path.join(get_config_dir(), "system.ini"),
        os.path.join(get_config_dir(), "local.ini"),
    ]

    return merge_config_files(*config_files)

""" Return a path to the standard configuration directory. """
def get_config_dir():
    return get_path("conf")

""" Return an absolute path to a project relative path. """
def get_path(relative_path=None):
    path_components = [os.path.dirname(__file__), "..", ".."]
    root_path = os.path.abspath(os.path.join(*path_components))

    if relative_path is None:
        return root_path
    else:
        return os.path.abspath(os.path.join(root_path, relative_path))

"""
Combine configuration files from one or more INI-style config files.

The config files are merged together in order. Later configuration
files can override earlier configuration files. Missing files are
ignored.

Use this mechanism for cascading configuration files. E.g.
one config file is version controlled and the other config file is
an optional, user-controlled file that can be used to customize a
local deployment.
"""
def merge_config_files(*paths):
    config = configparser.ConfigParser()
    config.optionxform = str
    config.read(paths)

    return config
