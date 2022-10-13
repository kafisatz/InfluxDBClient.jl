
@testset "Settings.jl                    " begin

    fi = normpath(joinpath(pathof(InfluxDBClient),"..","..","config_example.txt"))
  @show fi
@show isfile(fi)
  @test isfile(fi)

    senv = get_settings()
    s = get_settings(file=fi)
    sfi = get_settings_from_file(file=fi)

    for k in ["INFLUXDB_USER", "INFLUXDB_TOKEN", "INFLUXDB_HOST", "INFLUXDB_PASSWORD", "INFLUXDB_ORG"]
        @test haskey(senv,k)
        @test haskey(s,k)
        @test haskey(sfi,k)
    end
        
end
