import psycopg2

# Database connection
conn = psycopg2.connect("""
  dbname=xxxxxx
  user=xxxxxx
  password=xxxxxx
  host=xxxxx
  port=xxxxx
  options='-c search_path=enes_2013,public'  
  """)

cur = conn.cursor()

# Read the SQL script from file
with open("proj_etl.sql", "r") as f:
    sql_script = f.read()

# Execute the SQL script
cur.execute(sql_script)
conn.commit()  # Commit changes to the database

print("SQL script executed successfully!")

# Close connection
cur.close()
conn.close()
