#as per https://github.com/kafisatz/InfluxDBClient.jl/issues/2
#thank you https://github.com/amanica

#extract metadata
export extractStringListFromBody 
function extractStringListFromBody(body::Vector{UInt8})
    ret = Vector{AbstractString}()
    #@show body
    #@show String(deepcopy(body))
    iobuffer = IOBuffer(body)
    readuntil(iobuffer, '\n') # skip first line
    for line in eachline(iobuffer)
        #@show line
        lastCommaIndex = findlast(",", line)
        #@show lastCommaIndex
        if !isnothing(lastCommaIndex)            
            #note: SubString function fails on the line below, using copying accessor for now
                #line = ",_result,0,°C"
            #@show nextind(line,lastCommaIndex.stop+1)
            #@show value = SubString(line,lastCommaIndex.stop + 1, length(line))
            value = line[lastCommaIndex.stop + 1:end]
            push!(ret, value)
        end
    end
    return ret
end

export query_measurements
function query_measurements(isettings::Dict{String,String}, bucket::AbstractString)
    bucket_names,json = get_buckets(isettings)
    #@show bucket_names
    if !in(bucket,bucket_names)
        throw(ArgumentError("Bucket $bucket not found"))
    end
    extractStringListFromBody(query_flux(isettings, """import "influxdata/influxdb/schema"
        schema.measurements(
            bucket: "$bucket"
        )"""))
end

export query_measurement_field_keys 
function query_measurement_field_keys(isettings::Dict{String,String}, bucket::AbstractString, measurement::AbstractString)
    return extractStringListFromBody(query_flux(isettings, """import "influxdata/influxdb/schema"
        schema.measurementFieldKeys(
            bucket: "$bucket",
            measurement: "$measurement"
        )"""))
end

#=
    #a_random_bucket_name = "strom"
    #a_random_bucket_name = "hahistory"
    @show measurements = query_measurements(isettings, a_random_bucket_name)
    @show measurements = query_measurements(isettings, "strom")
    fields = query_measurement_field_keys(isettings, "strom", "stromzaehler")
    String(query_flux(isettings, """import "influxdata/influxdb/schema" schema.measurements(bucket: "$bucket")"""))

    for measurement in measurements
        fields = query_measurement_field_keys(isettings, a_random_bucket_name, measurement)
        println("$measurement : $(join(fields, ", "))")
    end
=#