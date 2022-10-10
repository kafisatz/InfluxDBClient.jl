export get_settings
function get_settings(;org::String="",token::String="",host::String="",user::String="",password::String="") #,bucket::String="")

    #maybe add an option to use something along ~/.influxdbconfig ? 

    if length(org) == 0 
        @assert haskey(ENV,"INFLUXDB_ORG")
        org = ENV["INFLUXDB_ORG"]
    end

    if length(host) == 0 
        @assert haskey(ENV,"INFLUXDB_HOST")
        host = ENV["INFLUXDB_HOST"]
    end

    if length(user) == 0 
        if haskey(ENV,"INFLUXDB_USER")
            user = ENV["INFLUXDB_USER"]
        end        
    end

    if length(password) == 0 
        if haskey(ENV,"INFLUXDB_PASSWORD")
            password = ENV["INFLUXDB_PASSWORD"]
        end        
    end

    if length(token) == 0 
        if haskey(ENV,"INFLUXDB_TOKEN")
            token = ENV["INFLUXDB_TOKEN"]
        else
            #try to get token via API
            if (length(user) == 0) || (length(password) == 0 )
                @warn("No token was provided and either user or password is missing.")
            end
        end
    end

    #if length(bucket) == 0
    #    if haskey(ENV,"INFLUXDB_BUCKET")
    #        bucket = ENV["INFLUXDB_BUCKET"]
    #    end
    #end

    isettings=(INFLUXDB_HOST=host,INFLUXDB_ORG=org,INFLUXDB_TOKEN=token,INFLUXDB_USER=user,INFLUXDB_PASSWORD=password)

    return isettings
end

export get_settings_from_file
function get_settings_from_file(;file="") 
    #=
    
    fi = raw"
    =#
    if length(file) <= 0 
        file = joinpath(ENV["USERPROFILE"],".influxdb","config")
    end
    if !isfile(file)
        throw(ArgumentError("File not found \r\n$(file)"))
    end
    txt = readlines(file)
    txt2 = split.(txt," ")
    for i=1:length(txt)
        @assert size(txt2[i],1) == 2
        k = txt2[i,1]
        v = txt2[i,1]        
        k = lstrip(rstrip(k))
        v = lstrip(rstrip(v))
    end

    return nothing 
end 