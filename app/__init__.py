from flask import Flask, jsonify
from flask_cors import CORS
from werkzeug.exceptions import HTTPException

from app.config import Config
from app.extensions import db


def create_app(config_overrides=None):
    app = Flask(__name__)
    app.config.from_object(Config)
    if config_overrides:
        app.config.update(config_overrides)

    CORS(app)
    db.init_app(app)

    from app.routes.audio import audio_bp
    from app.routes.video import video_bp
    app.register_blueprint(audio_bp)
    app.register_blueprint(video_bp)

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "message": "Server is running"})

    @app.errorhandler(HTTPException)
    def http_error(e):
        msg = "File too large" if e.code == 413 else e.description
        return jsonify({"status": "error", "message": msg}), e.code

    @app.errorhandler(Exception)
    def server_error(e):
        app.logger.exception(e)
        return jsonify({"status": "error", "message": "Internal server error"}), 500

    with app.app_context():
        db.create_all()   # DB setup: creates tables automatically on first run
    return app
