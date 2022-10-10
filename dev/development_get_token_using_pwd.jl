curl "http://ds.kroot:8086/query" --data-urlencode "u=bernhard" --data-urlencode "p=XXXXXXXXXXXXX" --data-urlencode "db=wpdaten" --data-urlencode "q=SELECT * FROM wpdaten"


http://user:password@host

@unpack INFLUXDB_HOST,INFLUXDB_TOKEN,INFLUXDB_USER,INFLUXDB_PASSWORD = isettings
limit=100
offset=0
r = HTTP.request("GET", """http://$(INFLUXDB_USER):$(INFLUXDB_PASSWORD)@$(INFLUXDB_HOST)/api/v2/buckets?limit=$limit&offset=$offset""", ["Content-Type"=>"text/plain; charset=utf-8","Accept"=>"application/json"] )

3r = HTTP.request("GET", """http://$(INFLUXDB_HOST)/api/v2/buckets?limit=$limit&offset=$offset""", ["Authorization" => "Token $(INFLUXDB_TOKEN)", "Content-Type"=>"text/plain; charset=utf-8","Accept"=>"application/json"] )