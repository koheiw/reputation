import calendar
import datetime, time
import configparser
from pymongo import MongoClient, errors
from newsdataapi import NewsDataApiClient

def download(date, col):
    
    col.create_index("article_id", unique = True)
    
    api = NewsDataApiClient(apikey = config['newsdata']['key'])
    
    page = None
    last = 0
    while True:
        data = api.archive_api(domainurl = "inquirer.net", page = page, sort = "pubdateasc",
                               from_date = date[0].isoformat()[0:10], to_date = date[1].isoformat()[0:10])
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

    cal = calendar.Calendar()
    for year in range(2025, 2027):
        for month in range(1, 13):
            date = (datetime.datetime(year, month, 1), 
                    datetime.datetime(year, month, max([d for d in cal.itermonthdays(year, month)])))
            print(f"{date[0].isoformat()[0:10]} to {date[1].isoformat()[0:10]}")
            download(date, db.newsdata)

    con.close()