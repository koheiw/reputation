import json
import configparser
from newsdataapi import NewsDataApiClient

if __name__ == "__main__":
    
    config = configparser.ConfigParser()
    config.read("settings.ini")
    
    country = "in"
    
    api = NewsDataApiClient(apikey = config['newsdata']['key'])
    data = api.sources_api(country = country)
    
    with open("sources/" + country + ".json", "w", encoding = "utf8") as f:
        json.dump(data['results'], f)
                               
