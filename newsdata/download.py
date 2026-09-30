import pandas as pd
import datetime, time, sys
import configparser
import yaml
from pymongo import MongoClient, errors
from newsdataapi import NewsDataApiClient

def check_log(source, date, col):
  
  res = col.find_one(
    {"source_id": source, "date": date}
  )
  if res == None:
    return -1
  else:
    return res["total"]
  
def save_log(source, date, total, col):

  col.create_index(["source_id", "date"], unique = True)
  col.update_one(
    {"source_id": source, "date": date}, 
    {"$set": {"total": total,
              "timestamp": datetime.datetime.now()}}, 
     upsert = True
  )

def download(source, date, col):
  
  col.create_index("article_id", unique = True)
  col.create_index("source_id", unique = False)
  api = NewsDataApiClient(apikey = config['newsdata']['key'])
  
  page = None
  last = 0
  while True:
    data = api.archive_api(domain = source, page = page, sort = "pubdateasc",
                           from_date = date[0].strftime("%Y-%m-%d"), 
                           to_date = date[1].strftime("%Y-%m-%d"))
    total = data['totalResults']
    if total == 0:
      return total
    
    if total > total_limit:
      exit(f"More than {total_limit} articles: {total}")
    
    articles = data['results']
    inserted = 0;
    for i in range(len(articles)):
      
      articles[i]['pubDate'] = datetime.datetime.fromisoformat(articles[i]['pubDate'])
      res = col.update_one(
        {"article_id": articles[i]['article_id']}, 
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
  
  con = MongoClient('localhost', 27017)
  db = con.reputation
  
  total_limit = 30000
  date_from = '2024-10-01'
  date_to = '2026-08-31'
  
  with open("sources.yaml") as stream:
      try:
          source = yaml.safe_load(stream)
      except yaml.YAMLError as e:
          print(e)

  for m in sys.argv[1:]: # country code via CLI
    print(f"Download", m)
    for s in source[m]:
      df = pd.DataFrame()
      df["from"] = pd.date_range(date_from, date_to, freq = 'MS')
      df["to"] = pd.date_range(date_from, date_to, freq = 'MS') + pd.offsets.MonthEnd(0)
      
      for index, row in df.iterrows():
        date = (row["from"], row["to"])
        done = check_log(s, date, db.log)
        if done >= 0:
          print(f"Skip {s} {date[0].strftime('%Y-%m-%d')} to {date[1].strftime('%Y-%m-%d')} {done}")
          continue
        print(f"Download {s} {date[0].strftime('%Y-%m-%d')} to {date[1].strftime('%Y-%m-%d')}")
        total = download(s, date, db.newsdata)
        save_log(s, date, total, db.log)

  con.close()
