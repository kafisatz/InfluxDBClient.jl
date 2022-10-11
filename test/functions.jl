
    function generate_data(nn)
        # do not change some_dt! 
        Random.seed!(123)
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

    function generate_data_ns(nn)
        # do not change some_dt! 
        Random.seed!(123)
        some_dt = DateTime(2022,9,30,15,59,33,0)
        some_nanodt = NanoDate(some_dt)
        sensor_id = ["TLM0900","TLM0901","TLM0901"]
        color = ["green","blue"]
    
        df = DataFrame(sensor_id =sample(sensor_id,nn),
                        color = sample(color,nn),
                        temperature = map(i->mod(1 + i,100)+0.3,1:nn),
                        an_int_value = map(i->mod(1 + i,100),1:nn),
                        abool = map(x->ifelse(x==1,true,false),rand(1:2,nn)),
                        humidity = rand(nn).^2 .*50,
                        co2 = map(i->mod(1 + i,100)*2,1:nn),
                        datetime = some_nanodt .- Nanosecond.(rand(1:Int(1e11),nn)));
        return df
    end

   function reset_bucket(isettings,a_random_bucket_name) 
        buckets,_ = get_buckets(isettings)
        if in(a_random_bucket_name,buckets)
            delete_bucket(isettings,a_random_bucket_name);
        end
        create_bucket(isettings,a_random_bucket_name);
        return nothing 
    end