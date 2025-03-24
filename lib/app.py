from fastapi import FastAPI, Query, HTTPException
import praw
import os
import pandas as pd
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from prophet import Prophet
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Reddit API credentials
REDDIT_CLIENT_ID = "_xJPfDpgyfFlI_gq6BrJbg"
REDDIT_CLIENT_SECRET = "Fer7i1SVwvg8zEsSUwDmrKI2ZBUPYA"
REDDIT_USER_AGENT = "python:ai_demo:v1.0 (by /u/Temporary_Muscle_817)"

# Initialize Reddit API
reddit = praw.Reddit(
    client_id=REDDIT_CLIENT_ID,
    client_secret=REDDIT_CLIENT_SECRET,
    user_agent=REDDIT_USER_AGENT
)

# Initialize FastAPI app
app = FastAPI()

@app.get("/fetch_reddit")
def fetch_reddit(subreddit: str = Query("technology", title="Subreddit", description="Enter a subreddit name"),
                 limit: int = Query(10, title="Limit", description="Number of posts to fetch", ge=1, le=100)):
    """
    Fetches Reddit posts, performs sentiment analysis & clustering.
    """
    posts = []
    analyzer = SentimentIntensityAnalyzer()

    try:
        # Fetch posts
        for submission in reddit.subreddit(subreddit).hot(limit=limit):
            sentiment = analyzer.polarity_scores(submission.title)
            posts.append({
                "title": submission.title,
                "score": submission.score,
                "sentiment": sentiment["compound"]
            })

        if not posts:
            raise HTTPException(status_code=404, detail="No posts found")

        # Convert to DataFrame
        df = pd.DataFrame(posts)

        # Text clustering
        vectorizer = TfidfVectorizer()
        X = vectorizer.fit_transform(df["title"])
        kmeans = KMeans(n_clusters=3, random_state=42).fit(X)
        df["cluster"] = kmeans.labels_

        return df.to_dict(orient="records")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/predict_trends")
def predict_trends(subreddit: str = Query("technology", title="Subreddit", description="Enter a subreddit name"),
                   days: int = Query(7, title="Days", description="Days to predict", ge=1, le=30)):
    """Predicts subreddit activity trends."""
    posts = []
    try:
        for submission in reddit.subreddit(subreddit).top(time_filter='month', limit=100):
            posts.append({"date": submission.created_utc, "score": submission.score})

        if not posts:
            raise HTTPException(status_code=404, detail="No posts found for trend prediction")

        df = pd.DataFrame(posts)
        df["date"] = pd.to_datetime(df["date"], unit="s")
        df = df.groupby("date").sum().reset_index()
        df.rename(columns={"date": "ds", "score": "y"}, inplace=True)

        model = Prophet()
        model.fit(df)
        future = model.make_future_dataframe(periods=days)
        forecast = model.predict(future)

        # ✅ Format date and round values
        forecast["ds"] = forecast["ds"].dt.strftime("%Y-%m-%d")
        forecast["yhat"] = forecast["yhat"].round(2)
        forecast["yhat_lower"] = forecast["yhat_lower"].round(2)
        forecast["yhat_upper"] = forecast["yhat_upper"].round(2)

        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(days).to_dict(orient='records')

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Run API using `uvicorn lib.app:app --reload`
