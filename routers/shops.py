from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timezone
from dotenv import load_dotenv
import os
import math
import requests

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

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

    address: str
    locality: str
    city: str
    pincode: str

    latitude: float
    longitude: float

    opening_time: str = ""
    closing_time: str = ""

    website: str = ""

    shop_images: list[str] = []
    interior_image: str = ""
    logo: str = ""


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

    address: str
    locality: str
    city: str
    pincode: str

    latitude: float
    longitude: float

    opening_time: str = ""
    closing_time: str = ""

    website: str = ""

    shop_images: list[str] = []
    interior_image: str = ""
    logo: str = ""


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

    return {
        "id": str(
            shop["_id"]
        ),

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

        "pincode": shop.get(
            "pincode",
            ""
        ),

        "latitude": coordinates[1],

        "longitude": coordinates[0],

        "opening_time": shop.get(
            "opening_time",
            ""
        ),

        "closing_time": shop.get(
            "closing_time",
            ""
        ),

        "website": shop.get(
            "website",
            ""
        ),

        "shop_images": shop.get(
            "shop_images",
            []
        ),

        "interior_image": shop.get(
            "interior_image",
            ""
        ),

        "logo": shop.get(
            "logo",
            ""
        ),

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
    earth_radius = 6371000

    lat1 = math.radians(
        lat1
    )

    lat2 = math.radians(
        lat2
    )

    delta_lat = math.radians(
        lat2 - lat1
    )

    delta_lon = math.radians(
        lon2 - lon1
    )

    a = (
        math.sin(
            delta_lat / 2
        ) ** 2
        +
        math.cos(lat1)
        *
        math.cos(lat2)
        *
        math.sin(
            delta_lon / 2
        ) ** 2
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
    query = f"""
    [out:json];
    (
      node["shop"](around:{radius},{latitude},{longitude});
      node["amenity"](around:{radius},{latitude},{longitude});
      node["tourism"](around:{radius},{latitude},{longitude});
    );
    out center;
    """

    servers = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
        "https://overpass.private.coffee/api/interpreter",
    ]

    elements = []

    for server in servers:
        try:
            response = requests.post(
                server,
                data=query,
                timeout=20
            )

            if response.status_code == 200:
                elements = response.json().get(
                    "elements",
                    []
                )

                if elements:
                    break

        except requests.RequestException:
            continue

    shops = []

    for element in elements:

        tags = element.get(
            "tags",
            {}
        )

        name = tags.get(
            "name"
        )

        if not name:
            continue

        lat = element.get(
            "lat"
        )

        lon = element.get(
            "lon"
        )

        if lat is None or lon is None:

            center = element.get(
                "center",
                {}
            )

            lat = center.get(
                "lat"
            )

            lon = center.get(
                "lon"
            )

        if lat is None or lon is None:
            continue

        distance = calculate_distance(
            latitude,
            longitude,
            lat,
            lon
        )

        shops.append({
            "id": str(
                element.get(
                    "id",
                    ""
                )
            ),

            "shop_name": name,

            "category": (
                tags.get("shop")
                or tags.get("amenity")
                or tags.get("tourism")
                or "other"
            ),

            "address": tags.get(
                "addr:street",
                ""
            ),

            "latitude": lat,

            "longitude": lon,

            "distance": round(
                distance
            ),

            "source": "osm",

            "status": "approved",

            "has_ad": False,
        })

    shops.sort(
        key=lambda shop:
        shop["distance"]
    )

    return {
        "count": len(shops),
        "shops": shops
    }


# ============================================================
# CREATE SHOP
# ============================================================

@router.post("/create")
def create_shop(
    request: CreateShopRequest
):

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

    if existing_shop:
        raise HTTPException(
            status_code=400,
            detail=
                "A shop already exists near this location"
        )

    shop = {

        "shop_name":
            request.shop_name,

        "category":
            request.category,

        "description":
            request.description,

        "owner_name":
            request.owner_name,

        "owner_email":
            request.owner_email,

        "phone":
            request.phone,

        "address":
            request.address,

        "locality":
            request.locality,

        "city":
            request.city,

        "pincode":
            request.pincode,

        "location": {
            "type": "Point",

            "coordinates": [
                request.longitude,
                request.latitude
            ]
        },

        "opening_time":
            request.opening_time,

        "closing_time":
            request.closing_time,

        "website":
            request.website,

        "shop_images":
            request.shop_images,

        "interior_image":
            request.interior_image,

        "logo":
            request.logo,

        "status":
            "pending",

        "created_at":
            datetime.now(
                timezone.utc
            ),

        "updated_at":
            datetime.now(
                timezone.utc
            )
    }

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

    shops = shops_collection.find({
        "owner_email":
            owner_email
    }).sort(
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
    # Find Existing Shop
    # --------------------------------------------------------

    existing_shop = shops_collection.find_one({
        "_id":
            ObjectId(shop_id)
    })

    if not existing_shop:

        raise HTTPException(
            status_code=404,
            detail="Shop not found"
        )

    # --------------------------------------------------------
    # Update Shop
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

                "owner_name":
                    request.owner_name,

                "owner_email":
                    request.owner_email,

                "phone":
                    request.phone,

                "address":
                    request.address,

                "locality":
                    request.locality,

                "city":
                    request.city,

                "pincode":
                    request.pincode,

                "location": {
                    "type":
                        "Point",

                    "coordinates": [
                        request.longitude,
                        request.latitude
                    ]
                },

                "opening_time":
                    request.opening_time,

                "closing_time":
                    request.closing_time,

                "website":
                    request.website,

                "shop_images":
                    request.shop_images,

                "interior_image":
                    request.interior_image,

                "logo":
                    request.logo,

                # Edited shops require
                # admin approval again.
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

    shops = shops_collection.find({
        "status":
            "pending"
    })

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
            "Shop approved successfully"
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
            "Shop rejected successfully"
    }


# ============================================================
# APPROVED SHOPS
# ============================================================

@router.get("/approved")
def get_approved_shops():

    shops = shops_collection.find({
        "status":
            "approved"
    })

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