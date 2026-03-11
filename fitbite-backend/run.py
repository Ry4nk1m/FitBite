import os
from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from flask_cors import CORS

from config import config_by_name
from app.models import db
from app.routes_auth import auth_bp
from app.routes_diary import diary_bp
from app.routes_goals_foods import goals_bp, foods_bp
from app.seed import seed_foods


def create_app(config_name=None):
    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "development")

    app = Flask(__name__)
    app.config.from_object(config_by_name[config_name])

    # Extensions
    db.init_app(app)
    JWTManager(app)
    CORS(app)

    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(diary_bp)
    app.register_blueprint(goals_bp)
    app.register_blueprint(foods_bp)

    # Health check
    @app.route("/api/health", methods=["GET"])
    def health():
        return jsonify({"status": "ok", "version": "1.0.0"}), 200

    # Error handlers
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Not found"}), 404

    @app.errorhandler(500)
    def server_error(e):
        return jsonify({"error": "Internal server error"}), 500

    # Create tables and seed
    with app.app_context():
        db.create_all()
        seed_foods()

    return app


# ─── Entry point ─────────────────────────────────────────────
if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5000, debug=True)
