from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import db, UserGoals, Food, CustomFood

goals_bp = Blueprint("goals", __name__, url_prefix="/api/goals")
foods_bp = Blueprint("foods", __name__, url_prefix="/api/foods")


# ─── Goals ───────────────────────────────────────────────────

@goals_bp.route("", methods=["GET"])
@jwt_required()
def get_goals():
    user_id = int(get_jwt_identity())
    goals = UserGoals.query.filter_by(user_id=user_id).first()
    if not goals:
        goals = UserGoals(user_id=user_id)
        db.session.add(goals)
        db.session.commit()
    return jsonify({"goals": goals.to_dict()}), 200


@goals_bp.route("", methods=["PUT"])
@jwt_required()
def update_goals():
    user_id = int(get_jwt_identity())
    data = request.get_json()
    goals = UserGoals.query.filter_by(user_id=user_id).first()

    if not goals:
        goals = UserGoals(user_id=user_id)
        db.session.add(goals)

    if "calories" in data:
        goals.calories = int(data["calories"])
    if "protein" in data:
        goals.protein = int(data["protein"])
    if "carbs" in data:
        goals.carbs = int(data["carbs"])
    if "fat" in data:
        goals.fat = int(data["fat"])

    db.session.commit()
    return jsonify({"goals": goals.to_dict()}), 200


# ─── Food Database Search ────────────────────────────────────

@foods_bp.route("/search", methods=["GET"])
@jwt_required()
def search_foods():
    """Search the food database. Query param: ?q=chicken&limit=20"""
    user_id = int(get_jwt_identity())
    query = request.args.get("q", "").strip()
    limit = min(int(request.args.get("limit", 20)), 50)

    if not query or len(query) < 2:
        return jsonify({"foods": [], "custom_foods": []}), 200

    # Search master food database
    foods = Food.query.filter(
        Food.name.ilike(f"%{query}%")
    ).limit(limit).all()

    # Search user's custom foods
    custom = CustomFood.query.filter(
        CustomFood.user_id == user_id,
        CustomFood.name.ilike(f"%{query}%")
    ).limit(10).all()

    return jsonify({
        "foods": [f.to_dict() for f in foods],
        "custom_foods": [f.to_dict() for f in custom],
    }), 200


@foods_bp.route("/custom", methods=["POST"])
@jwt_required()
def create_custom_food():
    """Create a custom food for the user."""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get("name"):
        return jsonify({"error": "name is required"}), 400

    food = CustomFood(
        user_id=user_id,
        name=data["name"],
        serving_description=data.get("serving_description"),
        calories=float(data.get("calories", 0)),
        protein=float(data.get("protein", 0)),
        carbs=float(data.get("carbs", 0)),
        fat=float(data.get("fat", 0)),
    )

    db.session.add(food)
    db.session.commit()

    return jsonify({"food": food.to_dict()}), 201


@foods_bp.route("/custom/<int:food_id>", methods=["DELETE"])
@jwt_required()
def delete_custom_food(food_id):
    user_id = int(get_jwt_identity())
    food = CustomFood.query.filter_by(id=food_id, user_id=user_id).first_or_404()
    db.session.delete(food)
    db.session.commit()
    return jsonify({"message": "Custom food deleted"}), 200
