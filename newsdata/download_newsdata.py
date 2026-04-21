import pandas as pd
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
    
    if (total > 10000):
      sys.exit("More than 10000 articles")

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
  
  date_from = '2024-06-01'
  date_to = '2025-12-31'
  
  url = ["inquirer.net",
         "mb.com.ph",
         "bandera.inquirer.net",
         "mediaindonesia.com",
         "republika.co.id"]
  
  for u in url:
    df = pd.DataFrame()
    df["from"] = pd.date_range(date_from, date_to, freq = 'MS')
    df["to"] = pd.date_range(date_from, date_to, freq = 'MS') + pd.offsets.MonthEnd(0)
    
    for index, row in df.iterrows():
      date = (row["from"].strftime("%Y-%m-%d"), row["to"].strftime("%Y-%m-%d"))
      total = check_log(u, date, db.log)
      if (total > 0):
        print(f"Skip {u} {date[0]} to {date[1]} {total}")
        continue
      print(f"Download {u} {date[0]} to {date[1]}")
      total = download(u, date, db.newsdata)
      save_log(u, date, total, db.log)

  con.close()
