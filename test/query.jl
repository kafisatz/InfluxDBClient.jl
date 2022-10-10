@testset "query.jl                      " begin

    create_bucket(isettings,a_random_bucket_name);

    #call without compression keyword
    payload = """myMeasurement,tag1=value1,tag2=value2 fieldKey="fieldValue" 1556813561098000000"""
    rs = write_data(isettings,a_random_bucket_name,payload,"ns")
    @test rs == 204

    #########################################################################################################
    #testing query function
    #########################################################################################################

    resp = query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"-100d"))
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
    @time write_data(isettings,a_random_bucket_name,lp,"s");

    adt = DateTime(2022,9,30,15,59,33,0)
    resp = query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"2022-09-30T15:59:00.752600+00:00"))
    @test isa(String(resp),String)

    datetime_str = string(adt,".00+00:00")
    @test isa(String(query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"))),String)

    datetime_str = string(adt-Hour(1),"+00:00")
    @test isa(String(query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"))),String)
    
    lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = true);
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    #with tags, fields and aggregation
    
    #mean
    datetime_str = string(DateTime(2022,9,30,15,59,33,0)-Hour(100),"+00:00")
    rs = query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate="mean()")
    @test isa(String(rs),String)

    #quantile 
    agg = """quantile(q: 0.99, method: "estimate_tdigest")"""
    rs = query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg)
    @test isa(String(rs),String)

    #complex aggreagation with window
    agg = """   aggregateWindow(every: 20m, fn: mean, createEmpty: false)
                |> yield(name: "mean") """
    bdy = query_flux_raw(isettings,a_random_bucket_name,"my_meas",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg);
    df = CSV.File(bdy) |> DataFrame
    DataFrames.select!(df,Not(:Column1)) #unclear what this could/would be (let us drop it for now)
    @test size(df) == (36,10)

    #get DataFrame
    df2 = query_flux(isettings,a_random_bucket_name,"my_meas";tzstr = "Europe/Berlin",range=Dict("start"=>"$datetime_str"),fields=["temperature","humidity"],tags=Dict("color"=>"blue"),aggregate=agg);
    @test size(df2) == (36,10)

    #=
        unc = round(Base.summarysize(lp)/1024/1024,digits=2)
        bdy = CodecZlib.transcode(CodecZlib.GzipCompressor, lp)
        comp = round(Base.summarysize(bdy)/1024/1024,digits=2)
        ratio = comp/unc
    =#

   
    delete_bucket(isettings,a_random_bucket_name);

end