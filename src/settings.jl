export get_settings
function get_settings(;org::String="",token::String="",url::String="",host::String="",user::String="",password::String="",file::String="") #,bucket::String="")

    #maybe add an option to use something along ~/.influxdbconfig ? 
    if length(file)>0
        settings_from_file = get_settings_from_file(;file=file)
        return _update_setting_keys(settings_from_file)
    else 
        settings_from_file = Dict{String,String}()
    end
    
    envsettings = Dict{String,String}()
    for k in ["INFLUXDB_PASSWORD","INFLUXDB_USER","INFLUXDB_URL","INFLUXDB_HOST","INFLUXDB_TOKEN","INFLUXDB_ORG"]
        if haskey(ENV,k)
            envsettings[k] = ENV[k]
        end
    end

    #kwargs should 'overwrite' environment variables
    kwsettings = envsettings 
    if length(org) > 0; kwsettings["INFLUXDB_ORG"] = org; end;
    if length(url) > 0; kwsettings["INFLUXDB_URL"] = url; end;
    if length(host) > 0; kwsettings["INFLUXDB_HOST"] = host; end;
    if length(token) > 0 ; kwsettings["INFLUXDB_TOKEN"] = token; end;
    if length(user) > 0 ; kwsettings["INFLUXDB_USER"] = user; end;
    if length(password) > 0 ; kwsettings["INFLUXDB_PASSWORD"] = password; end;

    #isettings=Dict{String,String}("INFLUXDB_HOST"=>host,"INFLUXDB_ORG"=>org,"INFLUXDB_TOKEN"=>token,"INFLUXDB_USER"=>user,"INFLUXDB_PASSWORD"=>password)

    #may want to inform/warn the user if there is overlap in the dicts... ? 
    #i guess the kw dict should have precedence
    isettings = merge(settings_from_file,envsettings,kwsettings)

    #isettings=Dict{String,String}("INFLUXDB_HOST"=>host,"INFLUXDB_ORG"=>org,"INFLUXDB_TOKEN"=>token,"INFLUXDB_USER"=>user,"INFLUXDB_PASSWORD"=>password)

    return _update_setting_keys(isettings)
end

function _update_setting_keys(isettings::Dict{String,String})
    if !haskey(isettings, "INFLUXDB_URL")
        # support INFLUXDB_HOST for backward compatibility
        isettings["INFLUXDB_URL"] = "http://" * isettings["INFLUXDB_HOST"]
    end
    delete!(isettings, "INFLUXDB_HOST")
    
    isettings["INFLUXDB_ORG"] = replace(isettings["INFLUXDB_ORG"], " " => "%20") 
    return isettings
end

export get_settings_from_file
function get_settings_from_file(;file="")
    isettings = Dict{String,String}()

    @show file
    if length(file) <= 0 
        file = joinpath(ENV["USERPROFILE"],".influxdb","config")
    end
    if !isfile(file)
        @show file
        throw(ArgumentError("File not found \r\n$(file)"))
    end
    txt = readlines(file)
    txt2 = split.(txt," ")
    for i=1:length(txt)
        @assert size(txt2[i],1) >= 2
        k = txt2[i][1]
        l = length(k)
        v = txt[i][l+2:end]
        k = lstrip(rstrip(k))
        v = lstrip(rstrip(v))
        isettings[k] = v 
    end

    return isettings 
end 