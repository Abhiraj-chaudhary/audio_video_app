from datetime import datetime, timezone

from app.extensions import db


class MediaMixin:
    id = db.Column(db.Integer, primary_key=True)
    file_name = db.Column(db.String(255), nullable=False)   # original name (sanitised)
    file_path = db.Column(db.String(255), nullable=False)   # stored name only, never a client path
    duration = db.Column(db.Integer, default=0)             # seconds
    file_size = db.Column(db.Integer, default=0)            # bytes
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self, kind):
        base = "/api/audio" if kind == "audio" else "/api/videos"
        return {
            "id": self.id,
            "file_name": self.file_name,
            "duration": self.duration,
            "file_size": self.file_size,
            "created_at": self.created_at.isoformat(),
            "file_url": f"{base}/{self.id}",
        }


class Audio(MediaMixin, db.Model):
    __tablename__ = "audio"


class Video(MediaMixin, db.Model):
    __tablename__ = "video"
