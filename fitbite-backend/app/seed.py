"""Seed the food database with common foods."""
from app.models import db, Food

SEED_FOODS = [
    # Proteins
    {"name": "Chicken Breast (grilled)", "serving_description": "6 oz", "calories": 280, "protein": 53, "carbs": 0, "fat": 6, "category": "protein"},
    {"name": "Salmon Fillet", "serving_description": "6 oz", "calories": 350, "protein": 38, "carbs": 0, "fat": 20, "category": "protein"},
    {"name": "Steak Sirloin", "serving_description": "6 oz", "calories": 320, "protein": 46, "carbs": 0, "fat": 14, "category": "protein"},
    {"name": "Turkey Breast (deli)", "serving_description": "4 oz", "calories": 120, "protein": 24, "carbs": 2, "fat": 1, "category": "protein"},
    {"name": "Tuna (canned in water)", "serving_description": "3 oz", "calories": 100, "protein": 22, "carbs": 0, "fat": 1, "category": "protein"},
    {"name": "Egg (large, whole)", "serving_description": "1 egg", "calories": 72, "protein": 6, "carbs": 0, "fat": 5, "category": "protein"},
    {"name": "Egg Whites", "serving_description": "3 large", "calories": 51, "protein": 11, "carbs": 0, "fat": 0, "category": "protein"},
    {"name": "Ground Beef (90% lean)", "serving_description": "4 oz", "calories": 200, "protein": 22, "carbs": 0, "fat": 11, "category": "protein"},
    {"name": "Shrimp", "serving_description": "4 oz", "calories": 120, "protein": 23, "carbs": 1, "fat": 2, "category": "protein"},
    {"name": "Tofu (firm)", "serving_description": "4 oz", "calories": 90, "protein": 10, "carbs": 2, "fat": 5, "category": "protein"},
    {"name": "Protein Shake (whey, 1 scoop)", "serving_description": "1 scoop + water", "calories": 120, "protein": 24, "carbs": 3, "fat": 1, "category": "protein"},

    # Dairy
    {"name": "Greek Yogurt (plain, nonfat)", "serving_description": "1 cup", "calories": 130, "protein": 22, "carbs": 8, "fat": 0, "category": "dairy"},
    {"name": "Cottage Cheese", "serving_description": "1 cup", "calories": 220, "protein": 25, "carbs": 8, "fat": 10, "category": "dairy"},
    {"name": "Milk (whole)", "serving_description": "1 cup", "calories": 149, "protein": 8, "carbs": 12, "fat": 8, "category": "dairy"},
    {"name": "Milk (2%)", "serving_description": "1 cup", "calories": 122, "protein": 8, "carbs": 12, "fat": 5, "category": "dairy"},
    {"name": "Cheddar Cheese", "serving_description": "1 oz", "calories": 113, "protein": 7, "carbs": 0, "fat": 9, "category": "dairy"},
    {"name": "Mozzarella Cheese", "serving_description": "1 oz", "calories": 85, "protein": 6, "carbs": 1, "fat": 6, "category": "dairy"},

    # Grains
    {"name": "Brown Rice (cooked)", "serving_description": "1 cup", "calories": 215, "protein": 5, "carbs": 45, "fat": 2, "category": "grain"},
    {"name": "White Rice (cooked)", "serving_description": "1 cup", "calories": 205, "protein": 4, "carbs": 45, "fat": 0, "category": "grain"},
    {"name": "Oatmeal (cooked)", "serving_description": "1 cup", "calories": 150, "protein": 5, "carbs": 27, "fat": 3, "category": "grain"},
    {"name": "Whole Wheat Bread", "serving_description": "1 slice", "calories": 81, "protein": 4, "carbs": 14, "fat": 1, "category": "grain"},
    {"name": "Pasta (cooked)", "serving_description": "1 cup", "calories": 220, "protein": 8, "carbs": 43, "fat": 1, "category": "grain"},
    {"name": "Quinoa (cooked)", "serving_description": "1 cup", "calories": 222, "protein": 8, "carbs": 39, "fat": 4, "category": "grain"},
    {"name": "Tortilla Wrap (large)", "serving_description": "1 wrap", "calories": 210, "protein": 5, "carbs": 36, "fat": 5, "category": "grain"},
    {"name": "Granola Bar", "serving_description": "1 bar", "calories": 190, "protein": 3, "carbs": 29, "fat": 7, "category": "grain"},

    # Fruits
    {"name": "Banana", "serving_description": "1 medium", "calories": 105, "protein": 1, "carbs": 27, "fat": 0, "category": "fruit"},
    {"name": "Apple", "serving_description": "1 medium", "calories": 95, "protein": 0, "carbs": 25, "fat": 0, "category": "fruit"},
    {"name": "Blueberries", "serving_description": "1 cup", "calories": 84, "protein": 1, "carbs": 21, "fat": 0, "category": "fruit"},
    {"name": "Strawberries", "serving_description": "1 cup", "calories": 49, "protein": 1, "carbs": 12, "fat": 0, "category": "fruit"},
    {"name": "Orange", "serving_description": "1 medium", "calories": 62, "protein": 1, "carbs": 15, "fat": 0, "category": "fruit"},
    {"name": "Avocado", "serving_description": "1/2 fruit", "calories": 160, "protein": 2, "carbs": 9, "fat": 15, "category": "fruit"},
    {"name": "Orange Juice", "serving_description": "8 oz", "calories": 112, "protein": 2, "carbs": 26, "fat": 0, "category": "fruit"},

    # Vegetables
    {"name": "Broccoli", "serving_description": "1 cup", "calories": 55, "protein": 4, "carbs": 11, "fat": 1, "category": "vegetable"},
    {"name": "Spinach (raw)", "serving_description": "2 cups", "calories": 14, "protein": 2, "carbs": 2, "fat": 0, "category": "vegetable"},
    {"name": "Sweet Potato", "serving_description": "1 medium", "calories": 103, "protein": 2, "carbs": 24, "fat": 0, "category": "vegetable"},
    {"name": "Potato (baked)", "serving_description": "1 medium", "calories": 161, "protein": 4, "carbs": 37, "fat": 0, "category": "vegetable"},
    {"name": "Carrots", "serving_description": "1 cup", "calories": 52, "protein": 1, "carbs": 12, "fat": 0, "category": "vegetable"},
    {"name": "Green Beans", "serving_description": "1 cup", "calories": 31, "protein": 2, "carbs": 7, "fat": 0, "category": "vegetable"},

    # Legumes
    {"name": "Black Beans", "serving_description": "1/2 cup", "calories": 114, "protein": 8, "carbs": 20, "fat": 0, "category": "legume"},
    {"name": "Chickpeas", "serving_description": "1/2 cup", "calories": 134, "protein": 7, "carbs": 22, "fat": 2, "category": "legume"},
    {"name": "Lentils (cooked)", "serving_description": "1/2 cup", "calories": 115, "protein": 9, "carbs": 20, "fat": 0, "category": "legume"},

    # Fats & Nuts
    {"name": "Almonds", "serving_description": "1 oz (~23 nuts)", "calories": 164, "protein": 6, "carbs": 6, "fat": 14, "category": "nuts"},
    {"name": "Peanut Butter", "serving_description": "2 tbsp", "calories": 190, "protein": 7, "carbs": 7, "fat": 16, "category": "nuts"},
    {"name": "Walnuts", "serving_description": "1 oz", "calories": 185, "protein": 4, "carbs": 4, "fat": 18, "category": "nuts"},
    {"name": "Olive Oil", "serving_description": "1 tbsp", "calories": 119, "protein": 0, "carbs": 0, "fat": 14, "category": "fat"},
    {"name": "Butter", "serving_description": "1 tbsp", "calories": 102, "protein": 0, "carbs": 0, "fat": 12, "category": "fat"},
    {"name": "Coconut Oil", "serving_description": "1 tbsp", "calories": 121, "protein": 0, "carbs": 0, "fat": 14, "category": "fat"},

    # Snacks & Other
    {"name": "Dark Chocolate (70%)", "serving_description": "1 oz", "calories": 170, "protein": 2, "carbs": 13, "fat": 12, "category": "snack"},
    {"name": "Hummus", "serving_description": "2 tbsp", "calories": 70, "protein": 2, "carbs": 4, "fat": 5, "category": "snack"},
    {"name": "Rice Cake", "serving_description": "1 cake", "calories": 35, "protein": 1, "carbs": 7, "fat": 0, "category": "snack"},
    {"name": "Trail Mix", "serving_description": "1/4 cup", "calories": 175, "protein": 5, "carbs": 15, "fat": 11, "category": "snack"},
    {"name": "Honey", "serving_description": "1 tbsp", "calories": 64, "protein": 0, "carbs": 17, "fat": 0, "category": "condiment"},
]


def seed_foods():
    """Insert seed foods if the table is empty."""
    if Food.query.first() is not None:
        return  # Already seeded

    for food_data in SEED_FOODS:
        food = Food(is_verified=True, **food_data)
        db.session.add(food)

    db.session.commit()
    print(f"Seeded {len(SEED_FOODS)} foods into the database.")
