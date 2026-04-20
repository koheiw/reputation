import calendar
import datetime, time
import configparser
from pymongo import MongoClient, errors
from newsdataapi import NewsDataApiClient

def check_log(url, date, col):
  
  date = (datetime.datetime.strptime(date[0], "%Y-%m-%d"),
          datetime.datetime.strptime(date[1], "%Y-%m-%d"))
  res = col.find_one(
      {"url": url, "date": date}
  )
  if res == None:
    return 0
  else:
    return res["total"]
  
def save_log(url, date, total, col):
  
  col.create_index(["url", "date"], unique = True)
  
  date = (datetime.datetime.strptime(date[0], "%Y-%m-%d"),
          datetime.datetime.strptime(date[1], "%Y-%m-%d"))
  
  col.update_one(
      {"url": url, "date": date}, 
      {"$set": {"total": total,
                "timestamp": datetime.datetime.now()}}, 
       upsert = True
  )

def download(url, date, col):
    
    col.create_index("article_id", unique = True)
    api = NewsDataApiClient(apikey = config['newsdata']['key'])
    
    page = None
    last = 0
    while True:
        data = api.archive_api(domainurl = url, page = page, sort = "pubdateasc",
                               from_date = date[0], to_date = date[1])
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
        page = data['nextPage']
        if not page:
            break
        time.sleep(1)
        
    return total

if __name__ == "__main__":
    
    config = configparser.ConfigParser()
    config.read("settings.ini")
    
    con = MongoClient('192.168.10.101', 27017)
    db = con.reputation
    
    #url = "inquirer.net"
    #url = "mb.com.ph"
    # ulr = "bandera.inquirer.net"
    url = "mediaindonesia.com"
    #url = "republika.co.id"
    
    cal = calendar.Calendar()
    for year in range(2025, 2026):
        for month in range(1, 13):
            date = (datetime.datetime(year, month, 1), 
                    datetime.datetime(year, month, max([d for d in cal.itermonthdays(year, month)])))
            date = (date[0].isoformat()[0:10], date[1].isoformat()[0:10])
            total = check_log(url, date, db.log)
            if (total > 0):
              print(f"Skip {date[0]} to {date[1]} {total}")
              continue
            print(f"Download {date[0]} to {date[1]}")  
            total = download(url, date, db.newsdata)
            save_log(url, date, total, db.log)

    con.close()
