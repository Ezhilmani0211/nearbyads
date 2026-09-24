from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timezone
from dotenv import load_dotenv
import os


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)

db = client["nearbyads"]

ads_collection = db["ads"]


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/api/ads",
    tags=["Advertisements"]
)


# ============================================================
# CREATE ADVERTISEMENT REQUEST
# ============================================================

class CreateAdvertisementRequest(BaseModel):

    owner_email: str

    shop_id: str

    title: str

    description: str

    discount: float

    radius: float

    start_date: str

    end_date: str

    offer_image: str = ""


# ============================================================
# UPDATE ADVERTISEMENT REQUEST
# ============================================================

class UpdateAdvertisementRequest(BaseModel):

    title: str

    description: str

    discount: float

    radius: float

    start_date: str

    end_date: str

    offer_image: str = ""


# ============================================================
# AD RESPONSE
# ============================================================

def ad_response(ad):

    return {

        "id":
            str(ad["_id"]),

        "owner_email":
            ad.get(
                "owner_email",
                ""
            ),

        "shop_id":
            ad.get(
                "shop_id",
                ""
            ),

        "title":
            ad.get(
                "title",
                ""
            ),

        "description":
            ad.get(
                "description",
                ""
            ),

        "discount":
            ad.get(
                "discount",
                0
            ),

        "radius":
            ad.get(
                "radius",
                0
            ),

        "start_date":
            ad.get(
                "start_date",
                ""
            ),

        "end_date":
            ad.get(
                "end_date",
                ""
            ),

        "offer_image":
            ad.get(
                "offer_image",
                ""
            ),

        "status":
            ad.get(
                "status",
                "pending"
            ),

        "created_at":
            ad.get(
                "created_at"
            ),

        "updated_at":
            ad.get(
                "updated_at"
            ),
    }


# ============================================================
# CREATE ADVERTISEMENT
# ============================================================

@router.post("/create")
def create_advertisement(
    request: CreateAdvertisementRequest
):

    # --------------------------------------------------------
    # Validate Shop ID
    # --------------------------------------------------------

    if not ObjectId.is_valid(
        request.shop_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid shop ID"
        )


    # --------------------------------------------------------
    # Check Shop
    # --------------------------------------------------------

    shop = db["shops"].find_one({
        "_id":
            ObjectId(
                request.shop_id
            )
    })


    if not shop:

        raise HTTPException(
            status_code=404,
            detail="Shop not found"
        )


    # --------------------------------------------------------
    # Check Owner
    # --------------------------------------------------------

    if shop.get(
        "owner_email"
    ) != request.owner_email:

        raise HTTPException(
            status_code=403,
            detail=
                "You are not the owner of this shop"
        )


    # --------------------------------------------------------
    # Create Advertisement
    # --------------------------------------------------------

    advertisement = {

        "owner_email":
            request.owner_email,

        "shop_id":
            request.shop_id,

        "title":
            request.title,

        "description":
            request.description,

        "discount":
            request.discount,

        "radius":
            request.radius,

        "start_date":
            request.start_date,

        "end_date":
            request.end_date,

        "offer_image":
            request.offer_image,

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


    result = ads_collection.insert_one(
        advertisement
    )


    return {

        "message":
            "Advertisement submitted for approval",

        "ad_id":
            str(
                result.inserted_id
            ),

        "status":
            "pending"
    }


# ============================================================
# MY ADS
# ============================================================

@router.get("/my-ads")
def get_my_ads(
    owner_email: str
):

    ads = ads_collection.find({
        "owner_email":
            owner_email
    }).sort(
        "created_at",
        -1
    )


    result = []


    for ad in ads:

        result.append(
            ad_response(
                ad
            )
        )


    return {

        "count":
            len(result),

        "ads":
            result
    }


# ============================================================
# UPDATE ADVERTISEMENT
# ============================================================

@router.put("/{ad_id}")
def update_advertisement(
    ad_id: str,
    request: UpdateAdvertisementRequest
):

    if not ObjectId.is_valid(
        ad_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid advertisement ID"
        )


    existing_ad = ads_collection.find_one({
        "_id":
            ObjectId(ad_id)
    })


    if not existing_ad:

        raise HTTPException(
            status_code=404,
            detail="Advertisement not found"
        )


    ads_collection.update_one(

        {
            "_id":
                ObjectId(ad_id)
        },

        {
            "$set": {

                "title":
                    request.title,

                "description":
                    request.description,

                "discount":
                    request.discount,

                "radius":
                    request.radius,

                "start_date":
                    request.start_date,

                "end_date":
                    request.end_date,

                "offer_image":
                    request.offer_image,

                # Edited ads need approval again
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
            "Advertisement updated and submitted for approval",

        "ad_id":
            ad_id,

        "status":
            "pending"
    }


# ============================================================
# PENDING ADS
# ============================================================

@router.get("/pending")
def get_pending_ads():

    ads = ads_collection.find({
        "status":
            "pending"
    })


    result = []


    for ad in ads:

        result.append(
            ad_response(
                ad
            )
        )


    return {

        "count":
            len(result),

        "ads":
            result
    }


# ============================================================
# APPROVE ADVERTISEMENT
# ============================================================

@router.put("/{ad_id}/approve")
def approve_advertisement(
    ad_id: str
):

    if not ObjectId.is_valid(
        ad_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid advertisement ID"
        )


    result = ads_collection.update_one(

        {
            "_id":
                ObjectId(ad_id)
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
            detail="Advertisement not found"
        )


    return {

        "message":
            "Advertisement approved successfully"
    }


# ============================================================
# REJECT ADVERTISEMENT
# ============================================================

@router.put("/{ad_id}/reject")
def reject_advertisement(
    ad_id: str
):

    if not ObjectId.is_valid(
        ad_id
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid advertisement ID"
        )


    result = ads_collection.update_one(

        {
            "_id":
                ObjectId(ad_id)
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
            detail="Advertisement not found"
        )


    return {

        "message":
            "Advertisement rejected successfully"
    }


# ============================================================
# APPROVED ADS
# ============================================================

@router.get("/approved")
def get_approved_ads():

    ads = ads_collection.find({
        "status":
            "approved"
    })


    result = []


    for ad in ads:

        result.append(
            ad_response(
                ad
            )
        )


    return {

        "count":
            len(result),

        "ads":
            result
    }