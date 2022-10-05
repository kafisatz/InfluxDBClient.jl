
@testset "Create and Delete Buckets.jl  " begin

    #get buckets
    #@time bucket_names,json = get_buckets_curl(isettings); #11ms btime, (influxdb host is on a different machine)
    @time bucket_names,json = get_buckets(isettings); #1.7 ms btime, (influxdb host is on a different machine)
    bucket_names
    @test length(bucket_names) > 0  #not sure if is possible to have ZERO buckets...? (_tasks, _monitoring) 

    #cleanup (if bucket exists from developping / testing)
    if in(a_random_bucket_name,bucket_names)
        @test isnothing(delete_bucket(isettings,a_random_bucket_name))
    end

    #create bucket
    json = create_bucket(isettings,a_random_bucket_name)
    @test json.name == a_random_bucket_name
    @test_throws ArgumentError create_bucket(isettings,a_random_bucket_name)
    
    bucket_names,json = get_buckets(isettings);
    @test in(a_random_bucket_name,bucket_names)

    #delete bucket
    @test isnothing(delete_bucket(isettings,a_random_bucket_name))

    @test_throws ArgumentError delete_bucket(isettings,a_random_bucket_name)

end
