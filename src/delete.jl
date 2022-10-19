#
export delete 

"""
the delete function assumes start and stop timestamps are UTC
function delete(isettings,bucket::String;measurement::String="",start::String="",stop::String="",tags=String[])        
"""
function delete(isettings,bucket::String;measurement::String="",start::Union{DateTime,String}="",stop::Union{DateTime,String}="",tags::Dict{String,String}=Dict{String,String}())
    #=
         bucket = a_random_bucket_name
    =#
    @unpack INFLUXDB_HOST,INFLUXDB_TOKEN,INFLUXDB_ORG = isettings
    organization_names,jsonORG = get_organizations(isettings)
    ORG_ID = get_orgid(jsonORG,INFLUXDB_ORG)

    hdrs = Dict("Authorization" => "Token $(INFLUXDB_TOKEN)", "Content-Type"=>"application/json")
    url = """http://$(INFLUXDB_HOST)/api/v2/delete?org=$INFLUXDB_ORG&bucket=$bucket"""

    if isa(start,DateTime) 
        start = string(start,"Z")
    end
    if isa(stop,DateTime) 
        stop = string(stop,"Z")
    end

    if iszero(length(start))
        start = INFLUXDB_TIME_MIN
    end 
    if iszero(length(stop))
        stop = INFLUXDB_TIME_MAX
    end 
    
    #specifying measurement and tag
    bdy = """{ "start": "$(start)",
        "stop": "$(stop)" """

    #"_measurement = airSensors and sensor_id=TLM0201",

    if !iszero(length(measurement)) || length(tags) > 0
        di = deepcopy(tags)
        if !iszero(length(measurement))
            di["_measurement"] = measurement
        end
        conditions = join([string(k, " = ",v) for (k,v) = di]," and ")
        #note the comma which needs to be inserted!
        bdy = string(bdy,""" , "predicate": """,'"', conditions, '"'," ")
    end
    
    #close bracket
    bdy = string(bdy,"}")
    @show bdy

    #validate json structure 
    #if this call fails, the HTTP request will likely fail too
    js = JSON3.read(bdy)

    #delete data
    r = HTTP.request("POST", url, hdrs, body = bdy)

    if r.status != 204
        @warn "Unexpected status" r.status
    end

    return r.status
end