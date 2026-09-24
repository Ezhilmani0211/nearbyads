import os
from dotenv import load_dotenv
from pymongo import MongoClient

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)

db = client["nearbyads"]

collections = [
    "users",
    "shops",
    "ads",
    "reviews",
    "notifications"
]

for collection_name in collections:
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name)
        print(f"Created: {collection_name}")
    else:
        print(f"Already exists: {collection_name}")

print("\nNearbyAds database setup completed!")