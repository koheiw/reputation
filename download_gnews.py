import json
import urllib.request
import calendar
import datetime, time
import configparser
from pymongo import MongoClient, errors

def download(date, col):
    
    col.create_index("id", unique = True)
    
    for page in range(1, 1001):
        url = f"https://gnews.io/api/v4/search?q=china&country=in&max=10&page={page}&apikey={config["gnews"]["key"]}&from={date[0].strftime("%Y-%m-%dT00:00:00.000Z")}&to={date[1].strftime("%Y-%m-%dT23:59:59.999Z")}"
        print(url)
        inserted = 0;
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode("utf-8"))
            total = data['totalArticles']  
            articles = data["articles"]
            for i in range(len(articles)):
                
                articles[i]['publishedAt'] = datetime.datetime.fromisoformat(articles[i]['publishedAt'])
                res = col.update_one(
                    {"id": articles[i]['id']}, 
                    {"$set": articles[i]}, 
                     upsert = True
                )
                inserted += 1 - res.matched_count
                
        print(f"{page * 10}/{total}: {inserted} inserted")
        if page * 10 > total:
            break
        time.sleep(5)
                
    return
  

if __name__ == "__main__":

    config = configparser.ConfigParser()
    config.read("settings.ini")

    con = MongoClient('192.168.10.101', 27017)
    db = con.reputation
   
    cal = calendar.Calendar()
    for year in range(2026, 2027):
        for month in range(4, 13):
            date = (datetime.datetime(year, month, 1), 
                    datetime.datetime(year, month, max([d for d in cal.itermonthdays(year, month)])))
            print(f"{date[0].isoformat()} to {date[1].isoformat()}")
            download(date, db.gnews)

    con.close()


