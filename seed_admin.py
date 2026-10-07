import bcrypt
from pymongo import MongoClient

# setup_database-ல் இருந்து db-ஐ பெறுகிறது, இல்லையெனில் புதிய இணைப்பை உருவாக்குகிறது
try:
    from setup_database import db
except Exception:
    client = MongoClient("mongodb://localhost:27017")
    db = client.nearbyads

def seed_admin():
    admin_email = "admin@nearbyads.com"
    existing_admin = db.users.find_one({"email": admin_email})
    
    if existing_admin:
        print("Admin user already exists!")
        return

    # Direct bcrypt hashing
    raw_password = "Admin@12345".encode('utf-8')
    hashed_password = bcrypt.hashpw(raw_password, bcrypt.gensalt()).decode('utf-8')

    admin_user = {
        "full_name": "System Admin",
        "email": admin_email,
        "password": hashed_password,
        "role": "admin",
        "email_verified": True
    }
    
    db.users.insert_one(admin_user)
    print("Admin user created successfully!")
    print(f"Email: {admin_email}")
    print("Password: Admin@12345")

if __name__ == "__main__":
    seed_admin()