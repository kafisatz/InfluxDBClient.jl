
@testset "Settings.jl                    " begin

    config_example_file = normpath(joinpath(pathof(InfluxDBClient),"..","..","config_example.txt"))
    @test isfile(config_example_file)
    config_host_example_file = normpath(joinpath(pathof(InfluxDBClient),"..","..","config_host_example.txt"))
    @test isfile(config_host_example_file)

    s_env = get_settings()
    s_config_example_file = get_settings(file=config_example_file)
    s_from_config_example_file = get_settings_from_file(file=config_example_file)

    s_config_host_example_file = get_settings(file=config_host_example_file)
    s_from_config_host_example_file = get_settings_from_file(file=config_host_example_file)

    for k in ["INFLUXDB_USER", "INFLUXDB_TOKEN", "INFLUXDB_URL", "INFLUXDB_PASSWORD", "INFLUXDB_ORG"]
        @test haskey(s_env, k)
        @test haskey(s_config_example_file, k)
        @test haskey(s_from_config_example_file, k)
        @test haskey(s_config_host_example_file, k)
    end

    for k in ["INFLUXDB_USER", "INFLUXDB_TOKEN", "INFLUXDB_HOST", "INFLUXDB_PASSWORD", "INFLUXDB_ORG"]
      @test haskey(s_from_config_host_example_file, k)
  end
        
end
