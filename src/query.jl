#todo 
@warn("query functions are in the works...")

#query_flux(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))

export query_flux 
function query_flux(isettings,bucket,measurement;range=Dict{String,Any}(),fields=Dict{String,Any}(),tags=Dict{String,Any}())
    #=
        df = DataFrame(_sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.1,55,22.0], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt-Second(51),some_dt-Second(500)])
        lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime,compress = gzip_compression_is_enabled)

        bucket = a_random_bucket_name
        measurement = "my_meas"
    =#

    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN,INFLUXDB_ORG = isettings
    
    #@assert length(range) > 0 #I think this may be necessary for any query...
    rngstr = ""
    if length(range) > 0 
        count = 0
        for (k,v) in range
            if count > 0 
                rngstr = string(rngstr," and ")
            end
            rngstr = string(k,": ",v)       
        end
        rngstr = string("range(",rngstr,")")
    end
    
    q = """from(bucket: "$(bucket)")"""
    if length(rngstr) > 0 
        q = string(q,"""|> """,rngstr)
    end
    #println(q)
    # |> range(start: -100d) """
    #q = """from(bucket: "$(bucket)")"""
    #TODO, implement range for function query_flux
    #TODO, implement tags for function query_flux
    #TODO, implement fields for function query_flux

    hdrs = Dict("Authorization" => "Token $(INFLUXDB_TOKEN)", "Accept"=>"application/json","Content-Type"=>"application/vnd.flux; charset=utf-8")
    hdrs["Content-Encoding"] = "identity"
    
    url = """http://$(INFLUXDB_HOST)/api/v2/query?org=$INFLUXDB_ORG"""
    bdy = q

    r = HTTP.request("POST", url, hdrs, body = bdy)
    if r.status != 200 
        @warn("Unexpected Status:")
        @show r.status
    end

    return r.body

#from(bucket: $(bucket))
#    |> range(start: -1h)
#    |> filter(fn: (r) => r._measurement == "example-measurement" and r.tag == "example-tag")
#    |> filter(fn: (r) => r._field == "example-field")
end 


#= 
need to support both
a) https://docs.influxdata.com/influxdb/v2.4/query-data/flux/
b) https://docs.influxdata.com/influxdb/v2.4/query-data/influxql/

a) 

a_random_bucket_name

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