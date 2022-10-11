#


@testset "Timezones.jl                   " begin

reset_bucket(isettings,a_random_bucket_name);

df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"], temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [now(),now()-Second(51),now()-Second(50)])
lp = lineprotocol("my_meas",df,["temperature","humidity"],tags=["sensor_id"], :datetime);
@test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

delete_bucket(isettings,a_random_bucket_name);

reset_bucket(isettings,a_random_bucket_name);

df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"], temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [now(),now()-Second(51),now()-Second(50)])
lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime, tags=["sensor_id"],tzstr="Europe/Berlin");
@test 204 == write_data(isettings,a_random_bucket_name,lp,"ns")

delete_bucket(isettings,a_random_bucket_name);


#test an ambiguous datetime 
some_dt = DateTime(2022,10,30,2,00,00,0)
df = DataFrame(sensor_id = ["TLM0900","TLM0901","TLM0901"], temperature = [73.9,55.1,22.9], humidity=[14.9,55.2,3], datetime = [some_dt,some_dt + Second(51),some_dt + Second(7200)])
@test_throws TimeZones.AmbiguousTimeError lp = lineprotocol("my_meas",df,["temperature","humidity"], :datetime, tags=["sensor_id"],tzstr="Europe/Berlin");

end