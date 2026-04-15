import calendar
import datetime, time
import configparser
from pymongo import MongoClient, errors
from newsdataapi import NewsDataApiClient


def download(col):
    
    col.create_index("article_id", unique = True)
    
    api = NewsDataApiClient(apikey = config['newsdata']['key'])
    
    page = None
    last = 0
    while True:
        data = api.latest_api(domainurl = "manilatimes.net", page = page)
        total = data['totalResults']
        articles = data['results']
        inserted = 0;
        for i in range(len(articles)):
            
            articles[i]['pubDate'] = datetime.datetime.fromisoformat(articles[i]['pubDate'])
            res = col.update_one(
                {"id": articles[i]['article_id']}, 
                {"$set": articles[i]}, 
                 upsert = True
            )
            inserted += 1 - res.matched_count
            
        last += len(articles)     
        print(f"{last}/{total}: {inserted} inserted")
        time.sleep(5)
        page = data['nextPage']
        if not page:
            break
    return 

if __name__ == "__main__":
    
    config = configparser.ConfigParser()
    config.read("settings.ini")
    
    con = MongoClient('192.168.10.101', 27017)
    db = con.reputation

    
    download(db.newsdata)
    #if not page:
    #    break
