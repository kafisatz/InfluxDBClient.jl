#todo 
#query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))

export query_flux
function query_flux(isettings,bucket,measurement;tzstr = "UTC",range=Dict{String,Any}(),fields::Vector{String}=String[],tags=Dict{String,Any}(),aggregate::String="")
    #tzstr is used to convert the datetime in Range to UTC
    tz = Dates.TimeZone(tzstr) #is of type TimeZone
    shift_datetime_to_utc(x) = DateTime(TimeZones.astimezone(TimeZones.ZonedDateTime(x, tz), utc_tz))

    #limitation / todo / tbd 
    #if range=-100d we DO NOT perform any modification of it!

    rangeUTC = Dict{String,Any}()
    for (k,v) in range
        if isa(v,DateTime)
            @show v
            @show k
            v_utc = shift_datetime_to_utc(v)
            datetime_str = string(v_utc,"+00:00")
            rangeUTC[k] = datetime_str
        else 
            rangeUTC[k] = v
        end
    end

    #perform query
    bdy = query_flux_raw(isettings,bucket,measurement,range=rangeUTC,fields=fields,tags=tags,aggregate=aggregate)
    
    #interpret as DataFrame 
    df = CSV.File(bdy) |> DataFrame
    DataFrames.select!(df,Not(:Column1)) #unclear what this could/would be (let us drop it for now)
    
    return df 
end

export query_flux_raw 
function query_flux_raw(isettings,bucket,measurement;range=Dict{String,Any}(),fields::Vector{String}=String[],tags=Dict{String,Any}(),aggregate::String="")
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
    
    #add range filter
    if length(rngstr) > 0 
        q = string(q,""" |> """,rngstr)
    end

    #filter for measurement
    if length(measurement) > 0 
        #|> filter(fn: (r) => r["_measurement"] == "my_meas")
        q = string(q,""" |> filter(fn: (r) => r["_measurement"] == """,'"',measurement,'"',")")
    end

    if length(fields)>0
        cnt = 1
        q = string(q,""" |> filter(fn: (r) => """)
        for f in fields 
            #  |> filter(fn: (r) => r["_field"] == "humidity" or r["_field"] == "temperature")
            q = string(q,""" r["_field"] == """,'"',f,'"')            
            if cnt < length(fields) 
                q = string(q," or ")
            end
            cnt += 1
        end
        q = string(q,")")
    end

    if length(tags)>0
        for (k,v) in tags 
            #|> filter(fn: (r) => r["color"] == "blue")
            q = string(q,""" |> filter(fn: (r) => r[""",'"',k,'"',"] == ",'"',v,'"',")")
        end
    end

    if length(aggregate) > 0 
        q = string(q,""" |> """,aggregate)
        #|> mean()
    end

    #https://docs.influxdata.com/flux/v0.x/function-types/#aggregates
    #aggregation functions can have parameters

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