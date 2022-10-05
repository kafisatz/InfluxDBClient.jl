@testset "Large Data.jl                  " begin
    create_bucket(isettings,a_random_bucket_name);


    function generate_data(nn)
        some_dt = DateTime(2022,9,30,15,59,33,0)
        sensor_id = ["TLM0900","TLM0901","TLM0901"]
        color = ["green","blue"]
    
        df = DataFrame(sensor_id =sample(sensor_id,nn),
                        color = sample(color,nn),
                        temperature = map(i->mod(1 + i,100)+0.3,1:nn),
                        an_int_value = map(i->mod(1 + i,100),1:nn),
                        abool = map(x->ifelse(x==1,true,false),rand(1:2,nn)),
                        humidity = rand(nn).^2 .*50,
                        co2 = map(i->mod(1 + i,100)*2,1:nn),
                        datetime = some_dt .- Second.(rand(1:nn,nn)));
        return df
    end
    #large_data
    
########################################################################
#without compression
#time to construct lp is NOT linear in nn
########################################################################

    nn = 10_000
    df = generate_data(nn)

    #@btime lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime);
    ela = @elapsed lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime);
    @test ela < 10
    # 5.5 seconds for 20k rows
    # 1.5 seconds for 10k rows
    # 10ms for 1k rows (not linear at all, damn strings)
    
    lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime);
    @time write_data(isettings,a_random_bucket_name,lp,"ns")
    @test length(findall('\n',lp)) == nn - 1 #only works if data has no \n
    
########################################################################
#with compression
#time to construct lp is linear in nn
########################################################################
    nn = 200_000
    df = generate_data(nn)
    
    ela = @elapsed lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = true);
    @test ela < 10
    # 0.3 seconds for 20k rows
    # 0.64 seconds for 40k rows
    # 1.4 seconds for 100k rows
    # 2.84 seconds for 200k rows

    #=
        unc = round(Base.summarysize(lp)/1024/1024,digits=2)
        bdy = CodecZlib.transcode(CodecZlib.GzipCompressor, lp)
        comp = round(Base.summarysize(bdy)/1024/1024,digits=2)
        ratio = comp/unc
    =#

    lp = lineprotocol("my_meas",df,["temperature","an_int_value","abool","humidity"],tags=["color","sensor_id"], :datetime,compress = true);
    @time write_data(isettings,a_random_bucket_name,lp,"ns")
    @test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

    delete_bucket(isettings,a_random_bucket_name);
end