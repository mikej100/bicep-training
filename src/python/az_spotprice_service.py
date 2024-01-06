#!/usr/bin/env python3
#
# Code derived from https://learn.microsoft.com/en-gb/rest/api/cost-management/retail-prices/azure-retail-prices
#
import datetime
import requests
import settings
import json
from mongo_manager import write_to_mongo

def main():
    fetch_and_store_prices()

def fetch_and_store_prices() :
    prices = fetch_price()
    timestamp = datetime.datetime.now()
    prices_with_date = prices
    [p.update({"timestamp": timestamp}) for p in prices_with_date]
    result = write_to_store(prices_with_date)
    return result

def fetch_price():
    query = "armSkuName eq 'Standard_NC4as_T4_v3' and priceType eq 'Consumption' and contains(meterName, 'Spot')"

    response = requests.get(settings.API_URI, params={'$filter': query})
    response_data = json.loads(response.text)
    
    price_data = response_data["Items"]
    nextPage = response_data['NextPageLink']
    
    while(nextPage):
        response = requests.get(nextPage)
        response_data = json.loads(response.text)
        nextPage = response_data['NextPageLink']
        price_data.append(response_data["Items"])

    return price_data


def write_to_store(data):
    return write_to_mongo(data)

if __name__ == "__main__":
    main()