from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timezone
from dotenv import load_dotenv
import os
import math


load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    raise RuntimeError("MONGO_URI is not configured in .env")

client = MongoClient(MONGO_URI)

db = client["nearbyads"]

shops_collection = db["shops"]

router = APIRouter(
    prefix="/api/shops",
    tags=["Shops"]
)


# ============================================================
# CREATE SHOP REQUEST
# ============================================================

class CreateShopRequest(BaseModel):
    shop_name: str
    category: str
    description: str = ""

    owner_name: str
    owner_email: str
    phone: str
    whatsapp: str = ""

    address: str
    locality: str
    city: str
    district: str = ""
    state: str = ""
    pincode: str

    latitude: float
    longitude: float

    opening_time: str = ""
    closing_time: str = ""
    open_24_hours: bool = False

    working_days: list[str] = []

    website: str = ""
    instagram: str = ""
    facebook: str = ""

    parking: bool = False
    home_delivery: bool = False
    online_order: bool = False
    upi: bool = False
    cash: bool = False

    offers_available: bool = False
    discount_available: bool = False
    advertisement_radius: float = 1000

# ============================================================
# UPDATE SHOP REQUEST
# ============================================================

class UpdateShopRequest(BaseModel):
    shop_name: str
    category: str
    description: str = ""

    owner_name: str
    owner_email: str
    phone: str
    whatsapp: str = ""

    address: str
    locality: str
    city: str
    district: str = ""
    state: str = ""
    pincode: str

    latitude: float
    longitude: float

    opening_time: str = ""
    closing_time: str = ""
    open_24_hours: bool = False

    working_days: list[str] = []

    website: str = ""
    instagram: str = ""
    facebook: str = ""

    parking: bool = False
    home_delivery: bool = False
    online_order: bool = False
    upi: bool = False
    cash: bool = False

    offers_available: bool = False
    discount_available: bool = False
    advertisement_radius: float = 1000
# ============================================================
# SHOP RESPONSE
# ============================================================

def shop_response(shop):
    location = shop.get(
        "location",
        {}
    )

    coordinates = location.get(
        "coordinates",
        [0, 0]
    )

    # MongoDB GeoJSON coordinates:
    # [longitude, latitude]

    longitude = coordinates[0]
    latitude = coordinates[1]

    return {
        "id": str(shop["_id"]),

        "shop_name": shop.get(
            "shop_name",
            ""
        ),

        "category": shop.get(
            "category",
            ""
        ),

        "description": shop.get(
            "description",
            ""
        ),

        # ----------------------------------------------------
        # OWNER
        # ----------------------------------------------------

        "owner_name": shop.get(
            "owner_name",
            ""
        ),

        "owner_email": shop.get(
            "owner_email",
            ""
        ),

        "phone": shop.get(
            "phone",
            ""
        ),

        "whatsapp": shop.get(
            "whatsapp",
            ""
        ),

        # ----------------------------------------------------
        # ADDRESS
        # ----------------------------------------------------

        "address": shop.get(
            "address",
            ""
        ),

        "locality": shop.get(
            "locality",
            ""
        ),

        "city": shop.get(
            "city",
            ""
        ),

        "district": shop.get(
            "district",
            ""
        ),

        "state": shop.get(
            "state",
            ""
        ),

        "pincode": shop.get(
            "pincode",
            ""
        ),

        # ----------------------------------------------------
        # LOCATION
        # ----------------------------------------------------

        "latitude": latitude,

        "longitude": longitude,

        # ----------------------------------------------------
        # OPENING HOURS
        # ----------------------------------------------------

        "opening_time": shop.get(
            "opening_time",
            ""
        ),

        "closing_time": shop.get(
            "closing_time",
            ""
        ),

        "open_24_hours": shop.get(
            "open_24_hours",
            False
        ),

        "working_days": shop.get(
            "working_days",
            []
        ),

        # ----------------------------------------------------
        # ONLINE DETAILS
        # ----------------------------------------------------

        "website": shop.get(
            "website",
            ""
        ),

        "instagram": shop.get(
            "instagram",
            ""
        ),

        "facebook": shop.get(
            "facebook",
            ""
        ),

        # ----------------------------------------------------
        # FACILITIES
        # ----------------------------------------------------

        "parking": shop.get(
            "parking",
            False
        ),

        "home_delivery": shop.get(
            "home_delivery",
            False
        ),

        "online_order": shop.get(
            "online_order",
            False
        ),

        "upi": shop.get(
            "upi",
            False
        ),

        "cash": shop.get(
            "cash",
            False
        ),

        # ----------------------------------------------------
        # OFFERS / ADVERTISEMENT SETTINGS
        # ----------------------------------------------------

        "offers_available": shop.get(
            "offers_available",
            False
        ),

        "discount_available": shop.get(
            "discount_available",
            False
        ),

        "advertisement_radius": shop.get(
            "advertisement_radius",
            1000
        ),

        # ----------------------------------------------------
        # STATUS
        # ----------------------------------------------------

        "status": shop.get(
            "status",
            "pending"
        ),

        "created_at": shop.get(
            "created_at"
        ),
    }


# ============================================================
# DISTANCE CALCULATION
# ============================================================

def calculate_distance(
    lat1,
    lon1,
    lat2,
    lon2
):
    """
    Calculate distance between two GPS coordinates
    using Haversine formula.

    Returns distance in meters.
    """

    earth_radius = 6371000

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)

    delta_lat = math.radians(
        lat2 - lat1
    )

    delta_lon = math.radians(
        lon2 - lon1
    )

    a = (
        math.sin(delta_lat / 2) ** 2
        +
        math.cos(lat1_rad)
        *
        math.cos(lat2_rad)
        *
        math.sin(delta_lon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a)
    )

    return earth_radius * c


# ============================================================
# NEARBY SHOPS
# ============================================================

@router.get("/nearby")
def get_nearby_shops(
    latitude: float,
    longitude: float,
    radius: int = 1000
):
    """
    Get approved shops from MongoDB
    within the requested radius.

    latitude  = user latitude
    longitude = user longitude
    radius    = meters
    """

    # --------------------------------------------------------
    # Validate radius
    # --------------------------------------------------------

    if radius <= 0:
        raise HTTPException(
            status_code=400,
            detail="Radius must be greater than 0"
        )

    # --------------------------------------------------------
    # Get approved shops
    # --------------------------------------------------------

    shops = shops_collection.find({
        "status": "approved"
    })

    nearby_shops = []

    # --------------------------------------------------------
    # Calculate distance
    # --------------------------------------------------------

    for shop in shops:

        location = shop.get(
            "location",
            {}
        )

        coordinates = location.get(
            "coordinates"
        )

        if not coordinates:
            continue

        if len(coordinates) != 2:
            continue

        # GeoJSON:
        # coordinates[0] = longitude
        # coordinates[1] = latitude

        shop_longitude = coordinates[0]
        shop_latitude = coordinates[1]

        distance = calculate_distance(
            latitude,
            longitude,
            shop_latitude,
            shop_longitude
        )

        # ----------------------------------------------------
        # Check radius
        # ----------------------------------------------------

        if distance <= radius:

            shop_data = shop_response(shop)

            shop_data["distance"] = round(
                distance
            )

            shop_data["source"] = "mongodb"

            shop_data["has_ad"] = False

            nearby_shops.append(
                shop_data
            )

    # --------------------------------------------------------
    # Sort nearest first
    # --------------------------------------------------------

    nearby_shops.sort(
        key=lambda shop: shop["distance"]
    )

    return {
        "count": len(
            nearby_shops
        ),

        "shops": nearby_shops
    }


# ============================================================
# CREATE SHOP
# ============================================================

@router.post("/create")
def create_shop(
    request: CreateShopRequest
):

    # --------------------------------------------------------
    # Validate advertisement radius
    # --------------------------------------------------------

    if request.advertisement_radius <= 0:
        raise HTTPException(
            status_code=400,
            detail="Advertisement radius must be greater than 0"
        )

    # --------------------------------------------------------
    # Check nearby duplicate shop
    # --------------------------------------------------------

    existing_shop = None

    try:

        existing_shop = shops_collection.find_one({
            "location": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [
                            request.longitude,
                            request.latitude
                        ]
                    },
                    "$maxDistance": 100
                }
            }
        })

    except Exception:
        # If 2dsphere index does not exist,
        # continue with normal insertion.
        existing_shop = None

    if existing_shop:

        raise HTTPException(
            status_code=400,
            detail="A shop already exists near this location"
        )

    # --------------------------------------------------------
    # Create timestamp
    # --------------------------------------------------------

    now = datetime.now(
        timezone.utc
    )

    # --------------------------------------------------------
    # Create shop document
    # --------------------------------------------------------

    shop = {

        "shop_name":
            request.shop_name,

        "category":
            request.category,

        "description":
            request.description,

        # ----------------------------------------------------
        # OWNER
        # ----------------------------------------------------

        "owner_name":
            request.owner_name,

        "owner_email":
            request.owner_email,

        "phone":
            request.phone,

        "whatsapp":
            request.whatsapp,

        # ----------------------------------------------------
        # ADDRESS
        # ----------------------------------------------------

        "address":
            request.address,

        "locality":
            request.locality,

        "city":
            request.city,

        "district":
            request.district,

        "state":
            request.state,

        "pincode":
            request.pincode,

        # ----------------------------------------------------
        # LOCATION
        # ----------------------------------------------------

        "location": {

            "type":
                "Point",

            "coordinates": [
                request.longitude,
                request.latitude
            ]
        },

        # ----------------------------------------------------
        # OPENING HOURS
        # ----------------------------------------------------

        "opening_time":
            request.opening_time,

        "closing_time":
            request.closing_time,

        "open_24_hours":
            request.open_24_hours,

        "working_days":
            request.working_days,

        # ----------------------------------------------------
        # ONLINE DETAILS
        # ----------------------------------------------------

        "website":
            request.website,

        "instagram":
            request.instagram,

        "facebook":
            request.facebook,

        # ----------------------------------------------------
        # FACILITIES
        # ----------------------------------------------------

        "parking":
            request.parking,

        "home_delivery":
            request.home_delivery,

        "online_order":
            request.online_order,

        "upi":
            request.upi,

        "cash":
            request.cash,

        # ----------------------------------------------------
        # OFFERS / ADVERTISEMENT
        # ----------------------------------------------------

        "offers_available":
            request.offers_available,

        "discount_available":
            request.discount_available,

        "advertisement_radius":
            request.advertisement_radius,

        # ----------------------------------------------------
        # STATUS
        # ----------------------------------------------------

        "status":
            "pending",

        "created_at":
            now,

        "updated_at":
            now
    }

    # --------------------------------------------------------
    # Insert
    # --------------------------------------------------------

    result = shops_collection.insert_one(
        shop
    )

    return {

        "message":
            "Shop submitted for approval",

        "shop_id":
            str(
                result.inserted_id
            ),

        "status":
            "pending"
    }


# ============================================================
# MY SHOPS
# ============================================================

@router.get("/my-shops")
def get_my_shops(
    owner_email: str
):

    shops = shops_collection.find(
        {
            "owner_email":
                owner_email
        }
    ).sort(
        "created_at",
        -1
    )

    result = []

    for shop in shops:

        result.append(
            shop_response(
                shop
            )
        )

    return {

        "count":
            len(result),

        "shops":
            result
    }


# ============================================================
# UPDATE SHOP
# ============================================================

@router.put("/{shop_id}")
def update_shop(
    shop_id: str,
    request: UpdateShopRequest
):

    # --------------------------------------------------------
    # Validate ObjectId
    # --------------------------------------------------------

    if not ObjectId.is_valid(
        shop_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid shop ID"
        )

    # --------------------------------------------------------
    # Validate advertisement radius
    # --------------------------------------------------------

    if request.advertisement_radius <= 0:
        raise HTTPException(
            status_code=400,
            detail="Advertisement radius must be greater than 0"
        )

    # --------------------------------------------------------
    # Find shop
    # --------------------------------------------------------

    existing_shop = shops_collection.find_one(
        {
            "_id":
                ObjectId(shop_id)
        }
    )

    if not existing_shop:

        raise HTTPException(
            status_code=404,
            detail="Shop not found"
        )

    # --------------------------------------------------------
    # Update
    # --------------------------------------------------------

    shops_collection.update_one(

        {
            "_id":
                ObjectId(shop_id)
        },

        {
            "$set": {

                "shop_name":
                    request.shop_name,

                "category":
                    request.category,

                "description":
                    request.description,

                # ------------------------------------------------
                # OWNER
                # ------------------------------------------------

                "owner_name":
                    request.owner_name,

                "owner_email":
                    request.owner_email,

                "phone":
                    request.phone,

                "whatsapp":
                    request.whatsapp,

                # ------------------------------------------------
                # ADDRESS
                # ------------------------------------------------

                "address":
                    request.address,

                "locality":
                    request.locality,

                "city":
                    request.city,

                "district":
                    request.district,

                "state":
                    request.state,

                "pincode":
                    request.pincode,

                # ------------------------------------------------
                # LOCATION
                # ------------------------------------------------

                "location": {

                    "type":
                        "Point",

                    "coordinates": [
                        request.longitude,
                        request.latitude
                    ]
                },

                # ------------------------------------------------
                # OPENING HOURS
                # ------------------------------------------------

                "opening_time":
                    request.opening_time,

                "closing_time":
                    request.closing_time,

                "open_24_hours":
                    request.open_24_hours,

                "working_days":
                    request.working_days,

                # ------------------------------------------------
                # ONLINE DETAILS
                # ------------------------------------------------

                "website":
                    request.website,

                "instagram":
                    request.instagram,

                "facebook":
                    request.facebook,

                # ------------------------------------------------
                # FACILITIES
                # ------------------------------------------------

                "parking":
                    request.parking,

                "home_delivery":
                    request.home_delivery,

                "online_order":
                    request.online_order,

                "upi":
                    request.upi,

                "cash":
                    request.cash,

                # ------------------------------------------------
                # OFFERS / ADVERTISEMENT
                # ------------------------------------------------

                "offers_available":
                    request.offers_available,

                "discount_available":
                    request.discount_available,

                "advertisement_radius":
                    request.advertisement_radius,

                # ------------------------------------------------
                # Edited shop requires admin approval again.
                # ------------------------------------------------

                "status":
                    "pending",

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            }
        }
    )

    return {

        "message":
            "Shop updated and submitted for approval",

        "shop_id":
            shop_id,

        "status":
            "pending"
    }


# ============================================================
# PENDING SHOPS
# ============================================================

@router.get("/pending")
def get_pending_shops():

    shops = shops_collection.find(
        {
            "status":
                "pending"
        }
    )

    result = []

    for shop in shops:

        result.append(
            shop_response(
                shop
            )
        )

    return {

        "count":
            len(result),

        "shops":
            result
    }


# ============================================================
# APPROVE SHOP
# ============================================================

@router.put("/{shop_id}/approve")
def approve_shop(
    shop_id: str
):

    if not ObjectId.is_valid(
        shop_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid shop ID"
        )

    result = shops_collection.update_one(

        {
            "_id":
                ObjectId(shop_id)
        },

        {
            "$set": {

                "status":
                    "approved",

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            }
        }
    )

    if result.matched_count == 0:

        raise HTTPException(
            status_code=404,
            detail="Shop not found"
        )

    return {

        "message":
            "Shop approved successfully",

        "shop_id":
            shop_id,

        "status":
            "approved"
    }


# ============================================================
# REJECT SHOP
# ============================================================

@router.put("/{shop_id}/reject")
def reject_shop(
    shop_id: str
):

    if not ObjectId.is_valid(
        shop_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid shop ID"
        )

    result = shops_collection.update_one(

        {
            "_id":
                ObjectId(shop_id)
        },

        {
            "$set": {

                "status":
                    "rejected",

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            }
        }
    )

    if result.matched_count == 0:

        raise HTTPException(
            status_code=404,
            detail="Shop not found"
        )

    return {

        "message":
            "Shop rejected successfully",

        "shop_id":
            shop_id,

        "status":
            "rejected"
    }


# ============================================================
# APPROVED SHOPS
# ============================================================

@router.get("/approved")
def get_approved_shops():

    shops = shops_collection.find(
        {
            "status":
                "approved"
        }
    ).sort(
        "created_at",
        -1
    )

    result = []

    for shop in shops:

        result.append(
            shop_response(
                shop
            )
        )

    return {

        "count":
            len(result),

        "shops":
            result
    }