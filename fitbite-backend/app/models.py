from datetime import datetime, date, timezone
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=True)  # nullable for social auth users
    auth_provider = db.Column(db.String(20), default="email")  # email, apple, google
    apple_id = db.Column(db.String(256), unique=True, nullable=True, index=True)
    google_id = db.Column(db.String(256), unique=True, nullable=True, index=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    goals = db.relationship("UserGoals", backref="user", uselist=False, cascade="all, delete-orphan")
    food_entries = db.relationship("FoodEntry", backref="user", cascade="all, delete-orphan")
    custom_foods = db.relationship("CustomFood", backref="user", cascade="all, delete-orphan")

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        if not self.password_hash:
            return False
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "username": self.username,
            "auth_provider": self.auth_provider,
            "created_at": self.created_at.isoformat(),
        }


class UserGoals(db.Model):
    __tablename__ = "user_goals"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, unique=True)
    calories = db.Column(db.Integer, default=2000)
    protein = db.Column(db.Integer, default=150)  # grams
    carbs = db.Column(db.Integer, default=250)     # grams
    fat = db.Column(db.Integer, default=65)        # grams
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
        }


class FoodEntry(db.Model):
    __tablename__ = "food_entries"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    date = db.Column(db.Date, nullable=False, index=True)
    meal_type = db.Column(db.String(20), nullable=False)  # breakfast, lunch, dinner, snacks
    food_name = db.Column(db.String(200), nullable=False)
    calories = db.Column(db.Float, nullable=False, default=0)
    protein = db.Column(db.Float, nullable=False, default=0)
    carbs = db.Column(db.Float, nullable=False, default=0)
    fat = db.Column(db.Float, nullable=False, default=0)
    quantity = db.Column(db.Float, default=1.0)
    logged_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Optional: link to a food from the database
    food_id = db.Column(db.Integer, db.ForeignKey("foods.id"), nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "date": self.date.isoformat(),
            "meal_type": self.meal_type,
            "food_name": self.food_name,
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
            "quantity": self.quantity,
            "logged_at": self.logged_at.isoformat(),
            "food_id": self.food_id,
        }


class Food(db.Model):
    """Master food database (shared across all users)."""
    __tablename__ = "foods"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, index=True)
    serving_description = db.Column(db.String(100))  # e.g., "1 cup cooked", "6 oz"
    calories = db.Column(db.Float, nullable=False)
    protein = db.Column(db.Float, nullable=False, default=0)
    carbs = db.Column(db.Float, nullable=False, default=0)
    fat = db.Column(db.Float, nullable=False, default=0)
    fiber = db.Column(db.Float, default=0)
    sugar = db.Column(db.Float, default=0)
    sodium = db.Column(db.Float, default=0)  # mg
    category = db.Column(db.String(50))  # protein, grain, fruit, vegetable, dairy, etc.
    is_verified = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "serving_description": self.serving_description,
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
            "fiber": self.fiber,
            "sugar": self.sugar,
            "sodium": self.sodium,
            "category": self.category,
        }


class CustomFood(db.Model):
    """User-created foods (private to each user)."""
    __tablename__ = "custom_foods"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    serving_description = db.Column(db.String(100))
    calories = db.Column(db.Float, nullable=False)
    protein = db.Column(db.Float, nullable=False, default=0)
    carbs = db.Column(db.Float, nullable=False, default=0)
    fat = db.Column(db.Float, nullable=False, default=0)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "serving_description": self.serving_description,
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
        }
