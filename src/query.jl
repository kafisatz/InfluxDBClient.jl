#todo 
#query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))

export query_flux



"""
    query_flux(isettings,bucket,measurement;parse_datetime=false,datetime_precision="ns",tzstr = "UTC",range=Dict{String,Any}(),fields::Vector{String}=String[],tags=Dict{String,Any}(),aggregate::String="")
    
    queries the database and returns a dataframe    
"""
function query_flux(isettings,bucket,measurement;parse_datetime=false,datetime_precision="ns",tzstr = "UTC",range=Dict{String,Any}(),fields::Vector{String}=String[],tags=Dict{String,Any}(),aggregate::String="")
    #tzstr = "Europe/Berlin"
    #tzstr is used to convert the datetime in Range to UTC
    tz = Dates.TimeZone(tzstr) #is of type TimeZone
    shift_datetime_to_utc(x) = DateTime(TimeZones.astimezone(TimeZones.ZonedDateTime(x, tz), utc_tz))
    shift_datetime_to_local(x) = DateTime(TimeZones.astimezone(TimeZones.ZonedDateTime(x, utc_tz), tz))

    #limitation / todo / tbd 
    #if range=-100d we DO NOT perform any modification of it!

    if !in(datetime_precision,PRECISIONS)
        throw(ArgumentError("Invalid precision: $(datetime_precision) is not an element of $PRECISIONS"))
    end

    rangeUTC = Dict{String,Any}()
    for (k,v) in range
        if isa(v,DateTime)
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

    #if there are zero rows, no need to parse anything
    if size(df,1) <= 0
        return df 
    end

    if parse_datetime
        #parse time
        #? should _start and _stop be discarded? 

        #influxdb can have different precision for different columns (unexpectedly)
        #for coln in [:_start,:_stop,:_time]
        for coln in [:_time]
            trimz = false
            #NOTE  a single column from InfluxDB can have a varying number of digits! (nanoseconds / ms / us precision)
            #row 1 can have more/fewer digits than the next row!
            #eg = ["2022-09-30T15:59:32.233Z", "2022-09-30T15:59:32.34Z"]
            ln = length(df[!,coln][1])            
            if !haskey(PRECISION_DATETIME_LENGTH,ln)
                idx = searchsortedfirst(DATETIME_LENGTHS,ln)
                if idx > length(DATETIME_LENGTHS)
                    throw(ArgumentError("Unexpected string length ($(ln)) for column _time"))
                end 
                ln2 = DATETIME_LENGTHS[idx]
                precision_of_data = PRECISION_DATETIME_LENGTH[ln2]                
            else 
                ln2 = ln
                precision_of_data = PRECISION_DATETIME_LENGTH[ln]    
            end

            #@show precision_of_data
            #@show df[1:3,:]
            
            if in(precision_of_data,["ns","us"])
                throw(ArgumentError("Precision ns and us is currently not supported for `query_flux`. Set the keyword parse_datetime to false to disable datetime parsing."))
                #note: NanoDates do not support TimeZones 
                #TimeZones do not support precision higher than ms
            else 
                #dates is sufficient
                if precision_of_data == "ms"
                    dfmt = dateformat"yyyy-mm-ddTHH:MM:SS.sss"
                    trimz = true
                else 
                    dfmt = dateformat"yyyy-mm-ddTHH:MM:SSz"
                end
                #DateTime.(df._time)
                #df._time[1]
                #TimeZones.ZonedDateTime("2019-11-18T13:09:31Z", dfmt)
                col = df[!,coln]
                #dt_local = shift_datetime_to_local.(string.(col))
                if trimz                
                    df[!,coln] = shift_datetime_to_local.(DateTime.(map(x->x[1:end-1],col), dfmt))
                else 
                    df[!,coln] = shift_datetime_to_local.(DateTime.(TimeZones.ZonedDateTime.(col, dfmt)))
                end
            end    
        end
    end

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
            #if v is a Date or DateTime add "+00:00" (UTC)
            if typeof(v) <: Dates.AbstractTime
                rngstr = string(k,": ",v,"+00:00")
            else
                rngstr = string(k,": ",v)
            end
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
    #@show q

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