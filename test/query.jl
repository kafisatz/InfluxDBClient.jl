@testset "query.jl                      " begin

    reset_bucket(isettings,a_random_bucket_name);

    #call without compression keyword
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns")
    @test rs == 204

    #########################################################################################################
    #testing query function
    #########################################################################################################

    resp = query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))
    @test typeof(resp) == Vector{UInt8}
    #next call should not throw an error 
    str = String(resp)
    @test typeof(str) == String
    @test length(str) > 0

    #########################################################################################################
    #generate data
    #########################################################################################################
    nn = 10_000
    df = generate_data(nn);
        
    lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = true,influx_precision="s");
    rs = write_data(isettings,a_random_bucket_name,lp,"s");
    @test rs == 204

    adt = DateTime(2022,9,30,15,59,33,0)
    resp = query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"2022-09-30T15:59:00.752600+00:00"))
    @test isa(String(resp),String)

    datetime_str = string(adt,".00+00:00")
    @test isa(String(query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"))),String)

    datetime_str = string(adt-Hour(1),"+00:00")
    @test isa(String(query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"))),String)
    
    lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = true);
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    #with tags, fields and aggregation
    
    #mean
    datetime_str = string(DateTime(2022,9,30,15,59,33,0)-Hour(100),"+00:00")
    rs = query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate="mean()")
    @test isa(String(rs),String)

    #quantile 
    agg = """quantile(q: 0.99, method: "estimate_tdigest")"""
    rs = query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg)
    @test isa(String(rs),String)

    #complex aggreagation with window
    agg = """   aggregateWindow(every: 20m, fn: mean, createEmpty: false)
                |> yield(name: "mean") """
    bdy = query_flux_http_response(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg);
    df = CSV.File(bdy) |> DataFrame
    DataFrames.select!(df,Not(:Column1)) #unclear what this could/would be (let us drop it for now)
    @test size(df) == (36,10)

    #get DataFrame
    df2 = query_flux(isettings,a_random_bucket_name,"my_meas";tzstr = "Europe/Berlin",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg);
    @test size(df2) == (36,10)

    ######################################################
    #parsing DateTime
    ######################################################
    for _ in 1:nmax_repeat_selected_query_tests
        for selected_precision in reverse(PRECISIONS)
            @info("Query (query_flux_http_response) - Testing precision roundtrip for precision = $(selected_precision)...")
            #define data
                ns_ts_int = 1556813561698123456
                dt = Dates.unix2datetime(trunc(div(ns_ts_int,PRECISION_DICT["s"])))
                #2019-05-02T16:12:41
                d = PRECISION_DICT[selected_precision]
                ts_int = div(ns_ts_int,d)
                ts = string(ts_int)
                payload = """myMeasurementWithPrecision$(selected_precision),tag1=value1,tag2=value2 fieldKeyX=123123i $(ts)"""
            #write data
                rs = write_data(isettings,a_random_bucket_name,payload,selected_precision)
                @test rs == 204
            #read data
                rs2 = query_flux_http_response(isettings,a_random_bucket_name,"myMeasurementWithPrecision$(selected_precision)",range=Dict("start"=>dt - Hour(1)),fields=["fieldKeyX"])
                rs3 = String(rs2)
                df2 = query_flux(isettings,a_random_bucket_name,"myMeasurementWithPrecision$(selected_precision)";tzstr = "Europe/Berlin",range=Dict("start"=>dt - Hour(1)),fields=["fieldKeyX"])
            #test consistency of roundtrip
                @test size(df2,1) == 1
                ts_result = df2._time[1]
                if selected_precision == "s"
                    #https://github.com/JuliaTime/NanoDates.jl/issues/21
                    ts_result = string(ts_result[1:end-1],".0Z")
                end
                #nd = NanoDate(ts_result)
                #@test nanodate2unixnanos(nd) == ts_int * d
                #2019-05-04T15:28:00.000Z
                #2019-05-02T16:12:41Z
                #=
                    NanoDate("2019-05-02T16:12:41.Z")
                    Date("2019-05-02T16:12:41Z")
                    @edit Date("2019-05-02T16:12:41Z")
                    fmt = dateformat"y-m-dTH:M:SZ"
                    DateTime("2019-05-02T16:12:41Z", "yyyy-mm-ddTHH:MM:SSZ")

                    DateTime("2019-05-02T16:12:41Z",fmt)
                    TimeZones.ZonedDateTime("2019-05-02T16:12:41Z")

                    dfff = dateformat"y-m-dTH:M:SZ"
                    dateformat"y-m-dTH:M:SZ"
                    DateTime("2019-11-18T13:09:31Z", dfff)
                    TimeZones.ZonedDateTime("2019-11-18T13:09:31Z", dateformat"yyyy-mm-dd\THH:MM:SSz")
                =#
        end
    end
    
    dfus = generate_data_ms(10000) #do not change the number, otherwise data will change!
    #currently writing DataFrame is only possible with s or ms precision 
    for _ in 1:nmax_repeat_selected_query_tests
        for selected_precision in ["ms","s"]
            for someTz in ["UTC","Europe/Berlin","Asia/Dubai"]
                if "s" == selected_precision
                    dfus = generate_data(10000) #do not change the number, otherwise data will change!
                else 
                    dfus = generate_data_ms(10000) #do not change the number, otherwise data will change!
                end
                @info("Query (query_flux) - Testing precision roundtrip for precision = $(selected_precision) and tz=$(someTz)...")

                lp = lineprotocol("my_meas$(selected_precision)",dfus,["temperature"],tags=["color","sensor_id"], :datetime,compress = false,tzstr = someTz,influx_precision=selected_precision);
                if someTz == "UTC"
                    #selecting first 100 characters, otherwise error message may be huge
                    selected_precision == "s" && @test startswith(lp[1:100],"my_meas$(selected_precision),color=green,sensor_id=TLM0901 temperature=2.3 1664553257\nmy_meas");
                    selected_precision == "ms" && @test startswith(lp[1:100],"my_meas$(selected_precision),color=green,sensor_id=TLM0901 temperature=2.3 1664547262564\nmy");
                end
                rs = write_data(isettings,a_random_bucket_name,lp,selected_precision);
                @test rs == 204
                
                #get DataFrame
                    df2 = query_flux(isettings,a_random_bucket_name,"my_meas$(selected_precision)";tzstr = someTz,parse_datetime=true,range=Dict("start"=>minimum(dfus.datetime)-Day(2)),fields=["temperature"]);
                    dfsub = filter(x->x.color=="blue",df2)
                            filter!(x->x.sensor_id=="TLM0900",dfsub)
                            select!(dfsub,Not([:_start,:_stop,:_measurement,:_field,:table,:result]))
                            rename!(dfsub,:_value=>:temperature)
                            rename!(dfsub,:_time=>:datetime)
                            select!(dfsub,[:datetime,:temperature,:color,:sensor_id])
                            sort!(dfsub,:datetime)

                    dfussub = filter(x->x.color=="blue",dfus)
                            filter!(x->x.sensor_id=="TLM0900",dfussub)
                            select!(dfussub,Not([:abool,:humidity,:co2,:an_int_value]))
                            unique!(dfussub)
                            select!(dfussub,[:datetime,:temperature,:color,:sensor_id])
                            sort!(dfussub,:datetime)
                
                #compare

                #if the timestamp of the data we sent is NOT unique, data was overwritte by the second line sent
                #let us only compare the entries where the ts is unique
                cm = countmap(dfussub.datetime)
                filter!(x->cm[x.datetime] <= 1,dfussub)
                filter!(x->haskey(cm,x.datetime) && cm[x.datetime] <= 1,dfsub)
                        
                @test size(dfsub,1) == size(dfussub,1)
                if selected_precision != "s"
                    @test dfsub.datetime == dfussub.datetime
                else
                    @test extrema(dfsub.datetime .- dfussub.datetime) == (Millisecond(0), Millisecond(0))
                end
            end
        end
    end 
    #=
        unc = round(Base.summarysize(lp)/1024/1024,digits=2)
        bdy = CodecZlib.transcode(CodecZlib.GzipCompressor, lp)
        comp = round(Base.summarysize(bdy)/1024/1024,digits=2)
        ratio = comp/unc
   
    =#

    delete_bucket(isettings,a_random_bucket_name);

end