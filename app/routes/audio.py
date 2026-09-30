from flask import Blueprint

from app.models import Audio
from app.services import media_service as svc

audio_bp = Blueprint("audio", __name__, url_prefix="/api/audio")


@audio_bp.post("/upload")
def upload_audio():
    return svc.handle_upload("audio", Audio, "/api/audio")


@audio_bp.get("")
def list_audio():
    return svc.handle_list("audio", Audio)


@audio_bp.get("/<int:item_id>")
def get_audio(item_id):
    return svc.handle_get("audio", Audio, item_id)


@audio_bp.delete("/<int:item_id>")
def delete_audio(item_id):
    return svc.handle_delete("audio", Audio, item_id)
