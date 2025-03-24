from fastapi import FastAPI
from pydantic import BaseModel
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import uvicorn

app = FastAPI()
analyzer = SentimentIntensityAnalyzer()

class TextRequest(BaseModel):
    text: str

@app.get("/")
def home():
    return {"message": "FastAPI Server is Running!"}

@app.post("/analyze")
def analyze_sentiment(request: TextRequest):
    score = analyzer.polarity_scores(request.text)
    sentiment = "Neutral"
    if score["compound"] >= 0.05:
        sentiment = "Positive"
    elif score["compound"] <= -0.05:
        sentiment = "Negative"
    return {"sentiment": sentiment}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
