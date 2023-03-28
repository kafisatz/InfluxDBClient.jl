@testset "Escape Chars.jl                " begin

    @test escape_special_chars(9) == 9
    @test escape_special_chars(9.) == 9.
    @test escape_special_chars(0x3) == 0x3
    @test escape_special_chars(0x3) == 0x3
    
    x = rand(UInt128)
    @test escape_special_chars(x) == x
    x = rand(UInt64)
    @test escape_special_chars(x) == x

    @test escape_special_chars(Complex(9)) == Complex(9)
    
end