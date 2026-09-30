from flask import Blueprint

from app.models import Video
from app.services import media_service as svc

video_bp = Blueprint("video", __name__, url_prefix="/api/videos")


@video_bp.post("/upload")
def upload_video():
    return svc.handle_upload("video", Video, "/api/videos")


@video_bp.get("")
def list_videos():
    return svc.handle_list("video", Video)


@video_bp.get("/<int:item_id>")
def get_video(item_id):
    return svc.handle_get("video", Video, item_id)


@video_bp.delete("/<int:item_id>")
def delete_video(item_id):
    return svc.handle_delete("video", Video, item_id)
