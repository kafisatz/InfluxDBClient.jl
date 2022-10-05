export get_settings
function get_settings(;org::String="",token::String="",host::String="") #,bucket::String="")

    #maybe add an option to use something along ~/.influxdbconfig ? 

    if length(org) == 0 
        @assert haskey(ENV,"INFLUXDB_ORG")
        org = ENV["INFLUXDB_ORG"]
    end

    if length(token) == 0 
        @assert haskey(ENV,"INFLUXDB_TOKEN")
        token = ENV["INFLUXDB_TOKEN"]
    end

    if length(host) == 0 
        @assert haskey(ENV,"INFLUXDB_HOST")
        host = ENV["INFLUXDB_HOST"]
    end
   
    #if length(bucket) == 0
    #    if haskey(ENV,"INFLUXDB_BUCKET")
    #        bucket = ENV["INFLUXDB_BUCKET"]
    #    end
    #end

    isettings=(INFLUXDB_HOST=host,INFLUXDB_ORG=org,INFLUXDB_TOKEN=token)

    return isettings
end