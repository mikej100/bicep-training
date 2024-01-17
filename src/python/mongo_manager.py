import logging
from pymongo import MongoClient
import settings

def write_to_mongo(data):
    client = MongoClient(settings.MONGO_URI)
    db = client[settings.MONGO_DB]
    logging.debug("Connected to MongoDB") 

    coll = db["spot_prices"]
    result = coll.insert_many(data)

    client.close()
    return result

def tester():
    return 1

def get_price_history(region):
    logging.debug("Enterd get_price_history")
    client = MongoClient(settings.MONGO_URI)
    db = client[settings.MONGO_DB]
    coll = db["spot_prices"]

    query = {"armRegionName": region}
    cursor = coll.find(query)
    result = list(cursor)

    a=1
    return result
