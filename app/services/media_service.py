"""File handling + validation shared by audio and video routes."""
import mimetypes
import os
import uuid

import mutagen
from flask import current_app, jsonify, request, send_file
from werkzeug.utils import secure_filename

from app.extensions import db


def error(message, status):
    return jsonify({"status": "error", "message": message}), status


def _folder(kind):
    path = os.path.join(current_app.config["UPLOAD_FOLDER"], kind)
    os.makedirs(path, exist_ok=True)
    return path


def _probe_duration(path):
    try:
        info = mutagen.File(path)
        if info is not None and info.info is not None:
            return int(info.info.length)
    except Exception:
        pass
    return None


def handle_upload(kind, model, url_prefix):
    if "file" not in request.files:
        return error("No file part named 'file' in the request", 400)
    f = request.files["file"]
    if not f.filename:
        return error("No file selected", 400)

    original = secure_filename(f.filename)
    ext = original.rsplit(".", 1)[-1].lower() if "." in original else ""
    if ext not in current_app.config["ALLOWED_EXTENSIONS"][kind]:
        return error(f"Unsupported {kind} type '.{ext}'", 415)

    stored = f"{uuid.uuid4().hex}.{ext}"          # server-generated name
    path = os.path.join(_folder(kind), stored)
    f.save(path)

    size = os.path.getsize(path)
    if size == 0:
        os.remove(path)
        return error("Uploaded file is empty", 400)

    duration = _probe_duration(path)
    if duration is None:
        if kind == "audio":                        # audio must be readable
            os.remove(path)
            return error("Audio file is corrupted or unsupported", 422)
        try:
            duration = int(float(request.form.get("duration", 0)))
        except ValueError:
            duration = 0

    record = model(file_name=original, file_path=stored, duration=duration, file_size=size)
    db.session.add(record)
    db.session.commit()
    return jsonify({
        "status": "success",
        "message": f"{kind.capitalize()} uploaded successfully",
        "file_id": str(record.id),
        "file_url": f"{url_prefix}/{record.id}",
    }), 201


def handle_list(kind, model):
    query = model.query.order_by(model.created_at.desc())
    q = request.args.get("q", "").strip()
    if q:
        query = query.filter(model.file_name.ilike(f"%{q}%"))   # bonus: search
    return jsonify({"status": "success", "items": [r.to_dict(kind) for r in query.all()]})


def _file_response(kind, record):
    path = os.path.join(_folder(kind), os.path.basename(record.file_path))
    if not os.path.isfile(path):
        return error("File missing on server", 404)
    mime = mimetypes.guess_type(path)[0] or "application/octet-stream"
    # conditional=True enables HTTP Range requests -> seeking works in players
    return send_file(path, mimetype=mime, conditional=True, download_name=record.file_name)


def handle_get(kind, model, item_id):
    record = db.session.get(model, item_id)
    if record is None:
        return error(f"{kind.capitalize()} {item_id} not found", 404)
    return _file_response(kind, record)


def handle_delete(kind, model, item_id):
    record = db.session.get(model, item_id)
    if record is None:
        return error(f"{kind.capitalize()} {item_id} not found", 404)
    path = os.path.join(_folder(kind), os.path.basename(record.file_path))
    if os.path.isfile(path):
        os.remove(path)
    db.session.delete(record)
    db.session.commit()
    return jsonify({"status": "success", "message": f"{kind.capitalize()} deleted"})
