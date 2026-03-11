import secrets
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
import jwt as pyjwt
import requests as http_requests
from app.models import db, User, UserGoals

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


# ─── Helper: find or create social user ──────────────────────

def _find_or_create_social_user(email, provider, provider_id, name=None):
    """Find existing user by provider ID or email, or create a new one."""

    # 1. Check by provider ID
    if provider == "apple":
        user = User.query.filter_by(apple_id=provider_id).first()
    elif provider == "google":
        user = User.query.filter_by(google_id=provider_id).first()
    else:
        user = None

    if user:
        return user

    # 2. Check by email (link accounts)
    user = User.query.filter_by(email=email.lower().strip()).first()
    if user:
        if provider == "apple":
            user.apple_id = provider_id
        elif provider == "google":
            user.google_id = provider_id
        db.session.commit()
        return user

    # 3. Create new user with unique username
    base_username = (name or email.split("@")[0]).lower().replace(" ", "")
    username = base_username
    counter = 1
    while User.query.filter_by(username=username).first():
        username = f"{base_username}{counter}"
        counter += 1

    user = User(
        email=email.lower().strip(),
        username=username,
        auth_provider=provider,
        apple_id=provider_id if provider == "apple" else None,
        google_id=provider_id if provider == "google" else None,
    )

    goals = UserGoals(user=user, calories=2000, protein=150, carbs=250, fat=65)
    db.session.add(user)
    db.session.add(goals)
    db.session.commit()

    return user


def _issue_tokens(user):
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    return {
        "user": user.to_dict(),
        "access_token": access_token,
        "refresh_token": refresh_token,
    }


# ─── Email Register ──────────────────────────────────────────

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()

    if not data or not data.get("email") or not data.get("password") or not data.get("username"):
        return jsonify({"error": "email, username, and password are required"}), 400

    if len(data["password"]) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400

    if User.query.filter_by(email=data["email"].lower().strip()).first():
        return jsonify({"error": "Email already registered"}), 409

    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "Username already taken"}), 409

    user = User(
        email=data["email"].lower().strip(),
        username=data["username"].strip(),
        auth_provider="email",
    )
    user.set_password(data["password"])

    goals = UserGoals(user=user, calories=2000, protein=150, carbs=250, fat=65)
    db.session.add(user)
    db.session.add(goals)
    db.session.commit()

    result = _issue_tokens(user)
    result["message"] = "Account created successfully"
    return jsonify(result), 201


# ─── Email Login ─────────────────────────────────────────────

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()

    if not data or not data.get("email") or not data.get("password"):
        return jsonify({"error": "email and password are required"}), 400

    user = User.query.filter_by(email=data["email"].lower().strip()).first()

    if not user or not user.check_password(data["password"]):
        return jsonify({"error": "Invalid email or password"}), 401

    return jsonify(_issue_tokens(user)), 200


# ─── Apple Sign In ───────────────────────────────────────────

@auth_bp.route("/apple", methods=["POST"])
def apple_sign_in():
    """
    iOS client sends:
    - identity_token: JWT from Apple
    - user_id: Apple's unique user identifier
    - email: (optional, only on first sign-in)
    - full_name: (optional, only on first sign-in)
    """
    data = request.get_json()

    if not data or not data.get("identity_token") or not data.get("user_id"):
        return jsonify({"error": "identity_token and user_id are required"}), 400

    identity_token = data["identity_token"]
    apple_user_id = data["user_id"]

    # Decode Apple JWT to extract email
    # PRODUCTION TODO: verify signature with Apple's public keys from
    # https://appleid.apple.com/auth/keys
    try:
        decoded = pyjwt.decode(identity_token, options={"verify_signature": False})
        email = decoded.get("email") or data.get("email")
    except Exception:
        email = data.get("email")

    if not email:
        user = User.query.filter_by(apple_id=apple_user_id).first()
        if user:
            return jsonify(_issue_tokens(user)), 200
        return jsonify({"error": "Email is required for first sign-in"}), 400

    full_name = data.get("full_name")
    user = _find_or_create_social_user(email, "apple", apple_user_id, name=full_name)

    return jsonify(_issue_tokens(user)), 200


# ─── Google Sign In ──────────────────────────────────────────

@auth_bp.route("/google", methods=["POST"])
def google_sign_in():
    """
    iOS client sends:
    - id_token: JWT from Google
    """
    data = request.get_json()

    if not data or not data.get("id_token"):
        return jsonify({"error": "id_token is required"}), 400

    id_token = data["id_token"]

    try:
        # Verify via Google's tokeninfo endpoint
        google_response = http_requests.get(
            f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}",
            timeout=10,
        )

        if google_response.status_code != 200:
            return jsonify({"error": "Invalid Google token"}), 401

        token_data = google_response.json()
        email = token_data.get("email")
        google_user_id = token_data.get("sub")
        name = token_data.get("name")

        if not email or not google_user_id:
            return jsonify({"error": "Could not extract user info from Google token"}), 400

    except http_requests.RequestException:
        return jsonify({"error": "Failed to verify Google token"}), 500

    user = _find_or_create_social_user(email, "google", google_user_id, name=name)

    return jsonify(_issue_tokens(user)), 200


# ─── Token Refresh ───────────────────────────────────────────

@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    user_id = get_jwt_identity()
    access_token = create_access_token(identity=user_id)
    return jsonify({"access_token": access_token}), 200


# ─── Profile ─────────────────────────────────────────────────

@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def get_profile():
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    return jsonify({"user": user.to_dict()}), 200


@auth_bp.route("/me", methods=["PUT"])
@jwt_required()
def update_profile():
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    data = request.get_json()

    if data.get("username"):
        existing = User.query.filter_by(username=data["username"]).first()
        if existing and existing.id != user.id:
            return jsonify({"error": "Username already taken"}), 409
        user.username = data["username"].strip()

    if data.get("password"):
        if len(data["password"]) < 6:
            return jsonify({"error": "Password must be at least 6 characters"}), 400
        user.set_password(data["password"])

    db.session.commit()
    return jsonify({"user": user.to_dict()}), 200
