import json, os, sys
import configparser
from newsdataapi import NewsDataApiClient

if __name__ == "__main__":
  
  config = configparser.ConfigParser()
  config.read("settings.ini")
  
  language = sys.argv[1]
  
  for i in range(1, 21):
    file = "sources2/" + language + "_" + "%03d" % i + ".json"
    if os.path.isfile(file):
      continue
    
    api = NewsDataApiClient(apikey = config['newsdata']['key'])
    data = api.sources_api(language = language)
    with open(file, "w", encoding = "utf8") as f:
      json.dump(data['results'], f)
                   
