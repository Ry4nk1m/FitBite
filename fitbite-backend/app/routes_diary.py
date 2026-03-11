from datetime import date, datetime, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func
from app.models import db, FoodEntry

diary_bp = Blueprint("diary", __name__, url_prefix="/api/diary")


@diary_bp.route("/entries", methods=["GET"])
@jwt_required()
def get_entries():
    """Get food entries for a specific date. Query param: ?date=YYYY-MM-DD"""
    user_id = int(get_jwt_identity())
    date_str = request.args.get("date", date.today().isoformat())

    try:
        target_date = date.fromisoformat(date_str)
    except ValueError:
        return jsonify({"error": "Invalid date format. Use YYYY-MM-DD"}), 400

    entries = FoodEntry.query.filter_by(
        user_id=user_id, date=target_date
    ).order_by(FoodEntry.logged_at.asc()).all()

    # Group by meal type
    grouped = {"breakfast": [], "lunch": [], "dinner": [], "snacks": []}
    for entry in entries:
        if entry.meal_type in grouped:
            grouped[entry.meal_type].append(entry.to_dict())

    # Calculate daily totals
    totals = {
        "calories": sum(e.calories for e in entries),
        "protein": sum(e.protein for e in entries),
        "carbs": sum(e.carbs for e in entries),
        "fat": sum(e.fat for e in entries),
    }

    return jsonify({
        "date": date_str,
        "meals": grouped,
        "totals": totals,
        "entry_count": len(entries),
    }), 200


@diary_bp.route("/entries", methods=["POST"])
@jwt_required()
def add_entry():
    """Add a food entry."""
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get("food_name") or not data.get("meal_type"):
        return jsonify({"error": "food_name and meal_type are required"}), 400

    if data["meal_type"] not in ("breakfast", "lunch", "dinner", "snacks"):
        return jsonify({"error": "meal_type must be breakfast, lunch, dinner, or snacks"}), 400

    entry_date = date.today()
    if data.get("date"):
        try:
            entry_date = date.fromisoformat(data["date"])
        except ValueError:
            return jsonify({"error": "Invalid date format"}), 400

    entry = FoodEntry(
        user_id=user_id,
        date=entry_date,
        meal_type=data["meal_type"],
        food_name=data["food_name"],
        calories=float(data.get("calories", 0)),
        protein=float(data.get("protein", 0)),
        carbs=float(data.get("carbs", 0)),
        fat=float(data.get("fat", 0)),
        quantity=float(data.get("quantity", 1.0)),
        food_id=data.get("food_id"),
    )

    db.session.add(entry)
    db.session.commit()

    return jsonify({"entry": entry.to_dict()}), 201


@diary_bp.route("/entries/<int:entry_id>", methods=["PUT"])
@jwt_required()
def update_entry(entry_id):
    """Update a food entry."""
    user_id = int(get_jwt_identity())
    entry = FoodEntry.query.filter_by(id=entry_id, user_id=user_id).first_or_404()
    data = request.get_json()

    if data.get("food_name"):
        entry.food_name = data["food_name"]
    if data.get("meal_type"):
        entry.meal_type = data["meal_type"]
    if "calories" in data:
        entry.calories = float(data["calories"])
    if "protein" in data:
        entry.protein = float(data["protein"])
    if "carbs" in data:
        entry.carbs = float(data["carbs"])
    if "fat" in data:
        entry.fat = float(data["fat"])
    if "quantity" in data:
        entry.quantity = float(data["quantity"])

    db.session.commit()
    return jsonify({"entry": entry.to_dict()}), 200


@diary_bp.route("/entries/<int:entry_id>", methods=["DELETE"])
@jwt_required()
def delete_entry(entry_id):
    """Delete a food entry."""
    user_id = int(get_jwt_identity())
    entry = FoodEntry.query.filter_by(id=entry_id, user_id=user_id).first_or_404()

    db.session.delete(entry)
    db.session.commit()

    return jsonify({"message": "Entry deleted"}), 200


@diary_bp.route("/summary", methods=["GET"])
@jwt_required()
def get_summary():
    """Get summary stats for a date range. Query params: ?start=YYYY-MM-DD&end=YYYY-MM-DD"""
    user_id = int(get_jwt_identity())
    end_date = date.today()
    start_date = end_date - timedelta(days=6)

    if request.args.get("start"):
        try:
            start_date = date.fromisoformat(request.args["start"])
        except ValueError:
            return jsonify({"error": "Invalid start date"}), 400
    if request.args.get("end"):
        try:
            end_date = date.fromisoformat(request.args["end"])
        except ValueError:
            return jsonify({"error": "Invalid end date"}), 400

    # Daily aggregates
    daily_stats = db.session.query(
        FoodEntry.date,
        func.sum(FoodEntry.calories).label("calories"),
        func.sum(FoodEntry.protein).label("protein"),
        func.sum(FoodEntry.carbs).label("carbs"),
        func.sum(FoodEntry.fat).label("fat"),
        func.count(FoodEntry.id).label("entry_count"),
    ).filter(
        FoodEntry.user_id == user_id,
        FoodEntry.date >= start_date,
        FoodEntry.date <= end_date,
    ).group_by(FoodEntry.date).order_by(FoodEntry.date.asc()).all()

    days = []
    for row in daily_stats:
        days.append({
            "date": row.date.isoformat(),
            "calories": round(row.calories or 0, 1),
            "protein": round(row.protein or 0, 1),
            "carbs": round(row.carbs or 0, 1),
            "fat": round(row.fat or 0, 1),
            "entry_count": row.entry_count,
        })

    # Calculate averages
    num_days = len(days) if days else 1
    avg = {
        "calories": round(sum(d["calories"] for d in days) / num_days, 1),
        "protein": round(sum(d["protein"] for d in days) / num_days, 1),
        "carbs": round(sum(d["carbs"] for d in days) / num_days, 1),
        "fat": round(sum(d["fat"] for d in days) / num_days, 1),
    }

    # Streak calculation
    streak = 0
    check_date = date.today()
    while True:
        has_entries = FoodEntry.query.filter_by(
            user_id=user_id, date=check_date
        ).first()
        if has_entries:
            streak += 1
            check_date -= timedelta(days=1)
        else:
            break

    return jsonify({
        "start": start_date.isoformat(),
        "end": end_date.isoformat(),
        "days": days,
        "averages": avg,
        "streak": streak,
    }), 200
