using Dates, Plots, Plots.Measures

function read_data(filepath::String)
    dates::Vector{Date} = []
    fell_asleep::Vector{Float64} = []
    woke_up::Vector{Time} = []
    sleep_quality::Vector{Int} = []
    time_awake::Vector{Time} = []
    session_start_vec::Vector{Vector{Time}} = []
    session_end_vec::Vector{Vector{Time}} = []
    meal_before_vec::Vector{Vector{Time}} = []
    activity_vec::Vector{Vector{String}} = []
    interest_level_vec::Vector{Vector{Int}} = []
    for line::String in eachline(filepath)
        println(line)
        line_vec = split(line, ";")
        # Adjusting fell_asleep to count more than 24 hours
        fell_asleep_00::Float64 = Dates.value(Time(String(line_vec[2]), "HH:MM"))/3600e9
        fell_asleep_24::Float64 = fell_asleep_00 < 3 ? fell_asleep_00 + 24 : fell_asleep_00
        push!(dates, Date(String(line_vec[1]), "dd.mm.yyyy"))
        push!(fell_asleep, fell_asleep_24)
        push!(woke_up, Time(String(line_vec[3]), "HH:MM"))
        push!(sleep_quality, parse(Int, String(line_vec[4])))
        push!(time_awake, Time(String(line_vec[5]), "HH:MM"))
        session_start::Vector{Time} = Time.(String.(split(line_vec[6], ", ")), "HH:MM")
        session_end::Vector{Time} = Time.(String.(split(line_vec[7], ", ")), "HH:MM")
        meal_before::Vector{Time} = Time.(String.(split(line_vec[8], ", ")), "HH:MM")
        activity::Vector{String} = String.(split(line_vec[9], ", "))
        interest_level::Vector{Int} = parse.(Int, String.(split(line_vec[10], ", ")))
        push!(session_start_vec, session_start)
        push!(session_end_vec, session_end)
        push!(meal_before_vec, meal_before)
        push!(activity_vec, activity)
        push!(interest_level_vec, interest_level)
    end
    return (
           dates, fell_asleep, woke_up, sleep_quality, time_awake,
           session_start_vec, session_end_vec, meal_before_vec,
           activity_vec, interest_level_vec
           )
end

function find_nr_of_sessions(session_start::Vector{Vector{Time}}, session_end::Vector{Vector{Time}})
    nr_of_sessions::Array{Int} = []
    for i::Int in eachindex(session_start)
        session_length::Vector{Nanosecond} = session_end[i] - session_start[i]
        if session_length != [Nanosecond(0)]
            push!(nr_of_sessions, length(session_length))
        else
            push!(nr_of_sessions, 0)
        end
    end
    return nr_of_sessions
end

function find_total_session_lengths(session_lengths)
    total_session_lengts::Vector{Time} = []
    for vec::Vector{Nanosecond} in session_lengths
        push!(total_session_lengts, Time(sum(vec)))
    end
    return total_session_lengts
end

function remove_zeros(vec)
    new_vec = []
    if typeof(vec) == Vector{Time}
        new_vec = vec[vec .!= Time(0,0,0)]
    elseif typeof(vec) == Vector{String}
        new_vec = vec[vec .!= ""]
    elseif typeof(vec) == Vector{Int}
        new_vec = vec[vec .!= 0]
    end
    return new_vec
end

# function find_session_indices(session_start::Vector{Vector{Time}}, session_end::Vector{Vector{Time}})
#     nr_of_sessions::Vector{Int} = find_nr_of_sessions(session_start, session_end)
#     session_indices::Vector{Int} = findall(!iszero, nr_of_sessions)
#     return session_indices
# end

# function find_session_elements(session_start::Vector{Vector{Time}}, session_end::Vector{Vector{Time}}, vec)
#     session_indices = find_session_indices(session_start, session_end)
#     session_elements = vec[session_indices]
#     return session_elements
# end