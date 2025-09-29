import os

def get_version_info():
    return {
    "version": os.getenv("APP_VERSION", "0.1.0"),
    "commit": os.getenv("GIT_SHA", "dev"),
    "env": os.getenv("APP_ENV", "local"),
    }