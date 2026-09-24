import os
from dotenv import load_dotenv
from pymongo import MongoClient

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    print("MONGO_URI not found in .env")
    exit()

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=10000)
    client.admin.command("ping")

    print("MongoDB connection successful!")

except Exception as e:
    print("MongoDB connection failed!")
    print(e)