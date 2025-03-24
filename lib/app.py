from fastapi import FastAPI, Query, HTTPException
import praw
import os
import pandas as pd
import spacy
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from prophet import Prophet
from wordcloud import WordCloud
from dotenv import load_dotenv
from transformers import pipeline
from collections import Counter

# Load environment variables
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

# Load NLP model for Named Entity Recognition (NER)
nlp = spacy.load("en_core_web_sm")

# Load advanced sentiment analysis model
sentiment_model = pipeline("sentiment-analysis")

@app.get("/fetch_reddit")
def fetch_reddit(subreddit: str = Query("technology"), limit: int = Query(10, ge=1, le=100)):
    """Fetches Reddit posts, performs sentiment analysis, clustering, and NER."""
    posts = []
    analyzer = SentimentIntensityAnalyzer()

    try:
        for submission in reddit.subreddit(subreddit).hot(limit=limit):
            # VADER sentiment analysis
            vader_sentiment = analyzer.polarity_scores(submission.title)

            # Transformer-based sentiment analysis
            transformer_sentiment = sentiment_model(submission.title)[0]

            # Named Entity Recognition
            doc = nlp(submission.title)
            entities = [ent.text for ent in doc.ents]

            posts.append({
                "title": submission.title,
                "score": submission.score,
                "vader_sentiment": vader_sentiment["compound"],
                "transformer_sentiment": transformer_sentiment["label"],
                "entities": entities
            })

        if not posts:
            raise HTTPException(status_code=404, detail="No posts found")

        df = pd.DataFrame(posts)

        # Text Clustering
        vectorizer = TfidfVectorizer()
        X = vectorizer.fit_transform(df["title"])
        kmeans = KMeans(n_clusters=3, random_state=42).fit(X)
        df["cluster"] = kmeans.labels_

        # Generate Word Cloud
        wordcloud = WordCloud(width=800, height=400, background_color="white").generate(" ".join(df["title"]))
        wordcloud.to_file("wordcloud.png")

        return df.to_dict(orient="records")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/predict_trends")
def predict_trends(subreddit: str = Query("technology"), days: int = Query(7, ge=1, le=30)):
    """Predicts subreddit activity trends and visualizes them."""
    posts = []
    try:
        for submission in reddit.subreddit(subreddit).top(time_filter='month', limit=100):
            posts.append({"date": submission.created_utc, "score": submission.score})

        if not posts:
            raise HTTPException(status_code=404, detail="No posts found")

        df = pd.DataFrame(posts)
        df["date"] = pd.to_datetime(df["date"], unit="s")
        df = df.groupby("date").sum().reset_index()
        df.rename(columns={"date": "ds", "score": "y"}, inplace=True)

        model = Prophet()
        model.fit(df)
        future = model.make_future_dataframe(periods=days)
        forecast = model.predict(future)

        # Plot the trend
        plt.figure(figsize=(10, 5))
        sns.lineplot(x=forecast["ds"], y=forecast["yhat"], label="Predicted Trend")
        sns.scatterplot(x=df["ds"], y=df["y"], color='red', label="Actual Data")
        plt.xticks(rotation=45)
        plt.savefig("trend_prediction.png")

        forecast["ds"] = forecast["ds"].dt.strftime("%Y-%m-%d")
        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(days).to_dict(orient='records')

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/top_entities")
def top_entities(subreddit: str = Query("technology"), limit: int = Query(50, ge=1, le=100)):
    """Extracts and counts the most common named entities from subreddit posts."""
    entities = []
    try:
        for submission in reddit.subreddit(subreddit).hot(limit=limit):
            doc = nlp(submission.title)
            entities.extend([ent.text for ent in doc.ents])

        if not entities:
            raise HTTPException(status_code=404, detail="No entities found")

        entity_counts = Counter(entities).most_common(10)
        return {"top_entities": entity_counts}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
