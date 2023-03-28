#InfluxDB OSS requires either org or orgID

export lineprotocol
"""
Creates a String in lineprotocol format given a measuremant name (String) and a DataFrame
Defaults used are 
influx_precision = 'ns'
tzstr = "UTC" # TimeZone string

```julia
df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"], temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [now(),now()-Second(51),now()-Second(50)])
lp = lineprotocol("measurement_name",df)
```
"""
function lineprotocol(measurement::String,df::AbstractDataFrame,fields0::Union{Vector{String},Vector{Symbol}},timestamp0;tags=String[],influx_precision="ns",tzstr = "UTC",compress::Bool=false)
    #=
        df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"],other_tag=["m","m","x"] ,temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [now(),now()-Second(51),now()-Second(50)])
        measurement = "my_measurement"
        fields0 = ["humidity","temperature"]
        tags = String["sensor_id","other_tag"]
        tags = String[]
        influx_precision = "ns"
        timestamp0 = :datetime

        Consider `list_of_timzones = TimeZones.timezone_names()` 
        tz = TimeZones.localzone()
        tz = Dates.TimeZone(tzstr)
    =#
    
    timestamp = Symbol(timestamp0)
    fields = Symbol.(fields0)
    tagsSymbols = Symbol.(tags)
    
    #check if variables exist 
    nms = propertynames(df)
    for f in vcat(fields...,tagsSymbols...,timestamp)
        if !in(f,nms)
            throw(ArgumentError("Column $(f) not found in DataFrame"))
        end
        #Measurement names, tag keys, and field keys cannot begin with an underscore _. The _ namespace is reserved for InfluxDB system use.
        #@show string.(f)[1]
        if string.(f)[1] == '_'
            throw(ArgumentError("Column $(f) starts with an underscore. This is not allowed"))
        end
    end
    (measurement[1] == '_')  && throw(ArgumentError("Measurment name $(measurement) starts with an underscore. This is not allowed"))

    if eltype(df[!,timestamp]) != DateTime
        throw(ArgumentError("Column $(timestamp) must be of type DateTime. It is $(eltype(df[!,timestamp]))"))
    end

    if !in(influx_precision,PRECISIONS)
        throw(ArgumentError("Invalid influx_precision: $(influx_precision) is not an element of $PRECISIONS"))
    end

    if size(df,1) == 0
        throw(ArgumentError("DataFrame has zero rows."))
    end

    #=
        i = 2
        rw = df[i,:]
        dt = rw[timestamp]
    =#

    #################################################################################
    #amend timezone in DataFrame such that we send UTC data to InfluxDB
    #################################################################################
    tz = Dates.TimeZone(tzstr) #is of type TimeZone

    #if tz == utc_tz
    #    shift_datetime_to_utc(x) = x
    #else 
        shift_datetime_to_utc(x) = DateTime(TimeZones.astimezone(TimeZones.ZonedDateTime(x, tz), utc_tz))
        #zdtlocal = TimeZones.ZonedDateTime.(df.datetime, tz)
        #zdtutc = TimeZones.astimezone.(zdtlocal, TimeZones.tz"UTC")    
        #dt = DateTime.(zdtutc)
    #end

    #broadcasting over Dataframe rows is not allowed... May need a different approach here
    #Line protocol: Lines separated by the newline character \n represent a single point in InfluxDB. Line protocol is whitespace sensitive.

    if compress
        codec = CodecZlib.GzipCompressor()
        CodecZlib.TranscodingStreams.initialize(codec)  # allocate resources
        lp = UInt8[]
        try
            lpstr_thisrow = create_lp(df[1,:],measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
            lp = transcode(codec, lpstr_thisrow)
            for i = 2:size(df,1)
                #add linebreak
                append!(lp,transcode(codec, "\n"))

                lpstr_thisrow = create_lp(df[i,:],measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)         
                data = transcode(codec, lpstr_thisrow)
                #add data to UInt8 array
                append!(lp,data)
            end
        catch
            rethrow()
        finally
            CodecZlib.TranscodingStreams.finalize(codec)  # free resources
        end

        return lp
    else

        lp = create_lp(df[1,:],measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
        for i = 2:size(df,1)
            lpstr_thisrow = create_lp(df[i,:],measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
            lp = string(lp,"\n",lpstr_thisrow)
        end
        return lp
    end

end

export create_lp
function create_lp(rw::DataFrameRow,measurement,timestamp,fields,tagsSymbols,influx_precision,shift_datetime_to_utc)
    #measurementName,tagKey=tagValue fieldKey="fieldValue" 1465839830100400200
    #tagsSymbols, escaping both keys and values for tags
    tstr = join(map(t->string(t,"=",escape_special_chars(rw[t])),escape_special_chars.(tagsSymbols)),",")

        ##If a tag key, tag value, or field key contains a space , comma ,, or an equals sign = it must be escaped using the backslash character \

    #fields
    #Always double quote string field values. More on quotes below.
    #myMeasurement fieldKey=12485903i integer
    #myMeasurement fieldKey=12485903u unsigned INT

    #fstr = join(map(t->string(t,"=",rw[t]),fields),",")
    #escaping only keys for fields
    if any(ismissing,rw)
        #NOTE: we skip columns where the data is missing!
        fstr = join(map(t->string(t,"=",lp_formatted_field_value(rw[t])),Iterators.filter(f->!ismissing(rw[f]),escape_special_chars.(fields))),",")
        #fstr = join(map(t->string(t,"=",lp_formatted_field_value(rw[t])),filter(f->!ismissing(rw[f]),fields)),",")
    else 
        fstr = join(map(t->string(t,"=",lp_formatted_field_value(rw[t])),escape_special_chars.(fields)),",")
    end
    #timestamp
    ts = get_milliseconds(shift_datetime_to_utc(rw[timestamp]))
    if influx_precision != "ms"
        if influx_precision == "ns"
            ts = ts * 1_000_000
        elseif influx_precision == "us"
            ts = ts * 1_000
        elseif influx_precision == "s"
            ts = div(ts,1000)
        end
    end

    additional_comma_for_tags = ifelse(length(tstr)>0, ",","")
    lpstr = string(measurement,additional_comma_for_tags,tstr," ",fstr, " ",ts)
    
    return lpstr
end

#const chars_that_need_to_be_quoted_in_influx = [' ', ',', '=']
##If a tag key, tag value, or field key contains a space , comma ,, or an equals sign = it must be escaped using the backslash character \
export escape_special_chars 
escape_special_chars(v::T) where {T<:AbstractFloat} = v
escape_special_chars(v::T) where {T<:Signed} = v
escape_special_chars(v::T) where {T<:Unsigned} = v
escape_special_chars(v::T) where {T<:Number} = v
escape_special_chars(s::AbstractString) = replace(s, r"([ ,=])" => s"\\\1")
escape_special_chars(s::Symbol) = Symbol(replace(string(s), r"([ ,=])" => s"\\\1"))

#export lp_formatted_field_value
lp_formatted_field_value(v::T) where {T<:AbstractFloat} = v
lp_formatted_field_value(v::T) where {T<:Signed} = string(v,"i")
lp_formatted_field_value(v::T) where {T<:Unsigned} = string(v,"u")
lp_formatted_field_value(v::T) where {T<:AbstractString} = string('"',v,'"')

lp_formatted_field_value(v::Bool) = v
#lp_formatted_field_value(v::Bool) = ifelse(v,"t","f") #might save a tiny tiny bit of data (using t instead of true)


export get_milliseconds
get_milliseconds(dt::DateTime) = Millisecond(Dates.value(dt) - Dates.UNIXEPOCH).value
#=
    #unclear which appraoch to pick for a given datetime
    dt = now()
    dt.instant.periods.value

    Millisecond(Dates.value(dt) - Dates.UNIXEPOCH).value
    trunc(Int,datetime2unix(dt)*1000)
=#