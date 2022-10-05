#todo 
@info("query functions are in the works...")
#= 
need to support both
a) https://docs.influxdata.com/influxdb/v2.4/query-data/flux/
b) https://docs.influxdata.com/influxdb/v2.4/query-data/influxql/

a) 

from(bucket: "example-bucket")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "example-measurement" and r.tag == "example-tag")
    |> filter(fn: (r) => r._field == "example-field")

    b) 

curl --get http://localhost:8086/query?db=example-db \
  --header "Authorization: Token YourAuthToken" \
  --data-urlencode "q=SELECT used_percent FROM example-db.example-rp.example-measurement WHERE host=host1"

  


curl -XPOST localhost:8086/api/v2/query -sS \
  -H 'Accept:application/csv' \
  -H 'Content-type:application/vnd.flux' \
  -d 'from(bucket:"telegraf")
        |> range(start:-5m)
        |> filter(fn:(r) => r._measurement == "cpu")'  

    =#