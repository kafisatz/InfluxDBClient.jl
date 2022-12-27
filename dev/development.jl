#dev snippets 

#extract metadata
function extractStringListFromBody(body::Vector{UInt8})
    ret = Vector{AbstractString}()
    iobuffer = IOBuffer(body)
    readuntil(iobuffer, '\n') # skip first line
    for line in eachline(iobuffer)
        lastCommaIndex = findlast(",", line)
        if !isnothing(lastCommaIndex)            
            #note: SubString function fails on the line below, using copying accessor for now
                #line = ",_result,0,°C"
            #@show nextind(line,lastCommaIndex.stop+1)
            #@show value = SubString(line,lastCommaIndex.stop + 1, length(line))
            value = line[lastCommaIndex.stop + 1:end]
            push!(ret, value)
        end
    end
    ret
end

function query_measurements(isettings::Dict{String,String}, bucket::AbstractString)
    bucket_names,json = get_buckets(isettings)
    @show bucket_names
    if !in(bucket,bucket_names)
        throw(ArgumentError("Bucket $bucket not found"))
    end
    extractStringListFromBody(query_flux(isettings, """import "influxdata/influxdb/schema"
        schema.measurements(
            bucket: "$bucket"
        )"""))
end

function query_measurement_field_keys(isettings::Dict{String,String}, bucket::AbstractString, measurement::AbstractString)
    extractStringListFromBody(query_flux(isettings, """import "influxdata/influxdb/schema"
        schema.measurementFieldKeys(
            bucket: "$bucket",
            measurement: "$measurement"
        )"""))
end

#a_random_bucket_name = "strom"
#a_random_bucket_name = "hahistory"
@show measurements = query_measurements(isettings, a_random_bucket_name)
String(query_flux(isettings, """import "influxdata/influxdb/schema" schema.measurements(bucket: "$bucket")"""))

for measurement in measurements
    fields = query_measurement_field_keys(isettings, a_random_bucket_name, measurement)
    println("$measurement : $(join(fields, ", "))")
end