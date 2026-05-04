from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from google import genai
from PIL import Image
import io
import json
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="FitLife Food Analyzer API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))


def build_prompt(goal: str) -> str:
    goal_map = {
        "Build Muscle": (
            "USER GOAL: BUILD MUSCLE. "
            "Prioritize protein content (aim 30g+ per meal). "
            "Flag if protein is too low. "
            "Suggest high-protein additions or swaps. "
            "Mention best timing (post-workout, pre-workout etc). "
            "Recommend complementary foods to boost muscle synthesis."
        ),
        "Lose Weight": (
            "USER GOAL: LOSE WEIGHT / FAT LOSS. "
            "Flag high-calorie or high-fat items. "
            "Warn if meal exceeds 500 calories. "
            "Highlight fiber and protein content (promote satiety). "
            "Suggest lower-calorie alternatives. "
            "Mention if the meal has hidden sugars or processed ingredients."
        ),
        "Improve Fitness": (
            "USER GOAL: IMPROVE GENERAL FITNESS. "
            "Give balanced macro advice. "
            "Highlight micronutrient benefits. "
            "Suggest nutrient-dense swaps if needed. "
            "Focus on energy, recovery, and overall health."
        ),
        "Maintain Weight": (
            "USER GOAL: MAINTAIN WEIGHT. "
            "Check macro balance. "
            "Flag extreme values (too high or too low). "
            "Suggest portion adjustments if needed. "
            "Keep advice moderate and sustainable."
        ),
    }

    goal_text = goal_map.get(
        goal,
        "USER GOAL: GENERAL HEALTH. Provide balanced nutritional advice."
    )

    return f"""
You are an expert nutritionist, dietitian, and fitness coach AI with deep knowledge of:
- Pakistani and South Asian cuisine (biryani, karahi, daal, roti, parathas, etc.)
- International cuisines
- Sports nutrition and body composition
- Micronutrient profiling

{goal_text}

Carefully analyze the food image. Be precise with nutrition estimates based on visible portion sizes.
For Pakistani/South Asian foods, use accurate traditional recipe nutritional data.

CRITICAL: Respond ONLY with a valid JSON object. No markdown. No code blocks. No extra text.

JSON structure (follow EXACTLY):
{{
  "is_food": true,
  "food_identified": "Full name of the dish/meal",
  "confidence": "high/medium/low",
  "description": "Appealing 1-2 sentence description of the food",
  "serving_size": "Estimated serving (e.g. 1 plate ~400g)",
  "cuisine_type": "Pakistani/Indian/Italian/American/etc.",
  "nutrition": {{
    "calories": 0,
    "protein_g": 0.0,
    "carbohydrates_g": 0.0,
    "fat_g": 0.0,
    "fiber_g": 0.0,
    "sugar_g": 0.0,
    "sodium_mg": 0.0,
    "cholesterol_mg": 0.0,
    "saturated_fat_g": 0.0,
    "potassium_mg": 0.0
  }},
  "ingredients_detected": [
    "ingredient with estimated quantity"
  ],
  "cooking_method": "Fried/Grilled/Baked/Boiled/Steamed/etc.",
  "health_score": 7,
  "health_score_reason": "Explanation of the 1-10 health score",
  "goal_alignment": {{
    "score": 7,
    "label": "Good/Excellent/Moderate/Poor",
    "feedback": "Specific detailed feedback for their {goal} goal"
  }},
  "positives": [
    "Specific nutritional positive point 1",
    "Specific nutritional positive point 2",
    "Specific nutritional positive point 3"
  ],
  "concerns": [
    "Specific concern 1",
    "Specific concern 2"
  ],
  "suggestions": [
    {{
      "title": "Short actionable title",
      "detail": "Detailed suggestion with specific quantities or alternatives",
      "priority": "high/medium/low",
      "impact": "How this suggestion helps their goal"
    }}
  ],
  "meal_timing": {{
    "best_time": "Pre-workout/Post-workout/Breakfast/Lunch/Dinner/Snack",
    "reason": "Why this timing works best for their goal"
  }},
  "alternative_meals": [
    {{
      "name": "Alternative meal name",
      "reason": "Why better for their goal",
      "estimated_calories": 0,
      "key_benefit": "Main nutritional advantage"
    }}
  ],
  "micronutrients": {{
    "vitamin_c": "high/moderate/low/none",
    "vitamin_b12": "high/moderate/low/none",
    "iron": "high/moderate/low/none",
    "calcium": "high/moderate/low/none",
    "potassium": "high/moderate/low/none",
    "zinc": "high/moderate/low/none",
    "magnesium": "high/moderate/low/none"
  }},
  "hydration_tip": "Specific hydration advice to pair with this meal",
  "weekly_frequency": "How many times per week this fits the goal",
  "pakistani_alternative": {{
    "exists": true,
    "name": "A Pakistani/local alternative if applicable",
    "benefit": "Why it might be better or similar"
  }}
}}

If image does NOT contain food, return ONLY:
{{
  "is_food": false,
  "message": "No food detected. Please upload a clear photo of your meal or food."
}}

Nutrition accuracy requirements:
- Use realistic portion-based estimates
- For Pakistani dishes: use traditional recipes as base (e.g. 1 serving biryani ~650 kcal, 1 paratha ~250 kcal)
- Account for oil/ghee in cooking methods
- Be specific: dont just say protein is present, give grams
"""


@app.post("/analyze-food")
async def analyze_food(
    file: UploadFile = File(...),
    goal: str = Form(default="Improve Fitness")
):
    # Validate file type
    # Accept any image type or unknown (mobile cameras sometimes send application/octet-stream)
    if file.content_type and not file.content_type.startswith("image/") \
            and file.content_type != "application/octet-stream":
        raise HTTPException(
            status_code=400,
            detail=f"Only image files supported. Got: {file.content_type}"
        )

    contents = await file.read()

    # 15MB limit
    if len(contents) > 15 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail="Image too large. Maximum 15MB."
        )

    try:
        image = Image.open(io.BytesIO(contents))

        # Convert RGBA/P to RGB (handles PNG with transparency)
        if image.mode in ("RGBA", "P", "LA"):
            image = image.convert("RGB")

        # Resize if too large (saves API tokens)
        max_size = (1024, 1024)
        image.thumbnail(max_size, Image.LANCZOS)

        prompt = build_prompt(goal)

        # Call Gemini Vision
        import PIL.Image
        response = client.models.generate_content(
        model="gemini-1.5-flash",
        contents=[prompt, image]
        )
        raw = response.text.strip()

        # Clean markdown code blocks if model adds them
        if "```json" in raw:
            raw = raw.split("```json")[1].split("```")[0].strip()
        elif "```" in raw:
            raw = raw.split("```")[1].split("```")[0].strip()

        result = json.loads(raw)

        if not isinstance(result, dict):
            raise ValueError("Invalid response structure from AI")

        return JSONResponse(content={
            "success": True,
            "data": result,
            "goal": goal,
            "model": "gemini-1.5-flash"
        })

    except json.JSONDecodeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI returned invalid JSON. Try again. Error: {str(e)}"
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        error_msg = str(e)
        if "API_KEY" in error_msg.upper():
            raise HTTPException(
                status_code=500,
                detail="Invalid Gemini API key. Check your .env file."
            )
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {error_msg}"
        )


@app.get("/health")
async def health_check():
    api_key = os.getenv("GEMINI_API_KEY", "")
    return {
        "status": "running",
        "service": "FitLife Food Analyzer",
        "api_key_configured": bool(api_key and len(api_key) > 10),
        "version": "1.0.0"
    }


@app.get("/")
async def root():
    return {
        "message": "FitLife Food Analyzer API",
        "endpoints": {
            "POST /analyze-food": "Upload food image for analysis",
            "GET /health": "Check server status"
        }
    }


if __name__ == "__main__":
    import uvicorn
    print("=" * 50)
    print("FitLife Food Analyzer API starting...")
    print("Visit: http://localhost:8000")
    print("Docs:  http://localhost:8000/docs")
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=8000)