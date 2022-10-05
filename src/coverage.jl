#https://github.com/JuliaCI/Coverage.jl

using Coverage
using CoverageTools
ma = analyze_malloc(".")  # could be "." for the current directory, or "src", etc.
0