import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


class Config:
    SQLALCHEMY_DATABASE_URI = "sqlite:///" + os.path.join(BASE_DIR, "media.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
    MAX_CONTENT_LENGTH = 200 * 1024 * 1024  # 200 MB hard limit -> HTTP 413
    ALLOWED_EXTENSIONS = {
        "audio": {"m4a", "mp3", "wav", "aac", "ogg", "flac"},
        "video": {"mp4", "mov", "mkv", "webm", "avi"},
    }
