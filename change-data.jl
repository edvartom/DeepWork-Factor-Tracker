using Distributions

nr_of_samples = 100

function int_vec_to_time_strings(vec2::Vector{Float64})
    vec3::Vector{Int64} = div.(vec2, 1)              # Hour
    vec4::Vector{Int64} = floor.(mod.(vec2, 1)*60)   # Minute
    vec5::Vector{String} = string.(vec3)
    vec6::Vector{String} = string.(vec4)
    for i in eachindex(vec5)
        if length(vec5[i]) == 1
            vec5[i] = "0" * vec5[i]
        end
        if length(vec6[i]) == 1
            vec6[i] = "0" * vec6[i]
        end
        if (length(vec5[i]) != 2) || (length(vec6[i]) != 2)
            error("error: length(vec5) != 2 OR length(vec6) != 2\nlength(vec5): $length(vec5)\nlength(vec6): $length(vec6)")
        end
    end
    vec7::Vector{String} = vec5 .* ":" .* vec6
    return vec7
end

function generate_dates(len::Int64)
    start_date::Date = Date(2026, 1, 1)
    date::Vector{Date} = collect(start_date : Day(1) : start_date + Day(len - 1))
    date_str::Vector{String} = Dates.format.(date, "dd.mm.yyyy")
    return date_str
end

function generate_fell_asleep(len::Int64)
    vec1::Vector{Float64} = rand(Normal(23.5, 1.0), len)
    vec2::Vector{Float64} = ifelse.(vec1 .>= 24, vec1 .- 24, vec1)
    vec3::Vector{String} = int_vec_to_time_strings(vec2)
    return vec3, vec2
end

function generate_woke_up(len::Int64)
    vec2::Vector{Float64} = rand(Normal(9.0, 2.0), len)
    for i in [1:7:length(vec2)]
        vec2[i] .= 7.0
    end
    vec3::Vector{String} = int_vec_to_time_strings(vec2)
    return vec3, vec2
end

function generate_sleep_quality(len::Int64)
    vec1::Vector{Int64} = ceil.(Int64, 10*rand(len))
    return string.(vec1)
end

function generate_hours_awake(len::Int64)
    vec1::Vector{Float64} = rand(Normal(0.5, 0.7), len)
    vec1[vec1 .< 0] .= 0
    vec2::Vector{String} = int_vec_to_time_strings(vec1)
    return vec2
end

function generate_session_times(interval_start::Float64, interval_end::Float64)
    session_duration::Float64 = rand(Normal(0.5, 0.25))
    session_duration = session_duration < 0.25 ? 0.25 : session_duration
    time_since_meal::Float64 = rand(Normal(2.0, 1.0))
    time_since_meal = time_since_meal < 0.05 ? 0.05 : time_since_meal
    session_start_float::Float64 = rand().*(interval_end - interval_start - session_duration - time_since_meal) .+ interval_start .+ time_since_meal
    session_end_float::Float64 = session_start_float + session_duration
    meal_before_float::Float64 = session_start_float - time_since_meal
    session_start_vec::Vector{String} = int_vec_to_time_strings([session_start_float])
    session_end_vec::Vector{String} = int_vec_to_time_strings([session_end_float])
    meal_before_vec::Vector{String} = int_vec_to_time_strings([meal_before_float])
    return session_start_vec[1], session_end_vec[1], meal_before_vec[1]
end

struct Activity
    title::String
    time_amount::Int64 # Number from 1 to 10, amount of day spent on this activity
    interest_level::Array{Int64} # Numbers from 1 to 10, how interesting what is concentrates on is
end

bird_watching::Activity = Activity(
    "Bird Watching", 1, [5,6,7,8,9]
)

solving_crossword::Activity = Activity(
    "Solving crossword", 3, [7,8,9]
)

going_for_a_walk::Activity = Activity(
    "Going for a walk", 5, [1,2,3,4,5,6,7,8,9,10]
)

woodworking::Activity = Activity(
    "Woodworking", 4, [4,5,6,7]
)

model_building::Activity = Activity(
    "Model building", 2, [4,5,6,7]
)

studying::Activity = Activity(
    "Studying", 10, [1,2,3,4,5,6,7,8,9,10]
)

resting::Activity = Activity(
    "Resting", 3, [4,5,6,7,8,9,10]
)

gardening::Activity = Activity(
    "Gardening", 1, [10]
)

golfing::Activity = Activity(
    "Golfing", 5, [7,8,9]
)

cooking::Activity = Activity(
    "Cooking", 1, [9,10]
)

reading::Activity = Activity(
    "Reading", 5, [2,3,4,5,6,7,8,9,10]
)

listening_to_records::Activity = Activity(
    "Listening to records", 6, [4,5,6,7,8,9,10]
)

activity_vec = [
    bird_watching, solving_crossword, going_for_a_walk,
    woodworking, model_building, studying, resting, gardening,
    golfing, cooking, reading, listening_to_records
]

function generate_activity_and_interest_level(activity_vec::Vector{Activity})
    activity_time_amounts::Vector{Int64} = getproperty.(activity_vec, :time_amount)
    activity_index::Int64 = rand(Categorical(activity_time_amounts ./ sum(activity_time_amounts)))
    activity_during_session::Activity = activity_vec[activity_index]
    activity_title::String = activity_during_session.title
    interest_level_vec::Vector{Int64} = activity_during_session.interest_level
    interest_level::String = string(ceil(Int64, rand() * length(interest_level_vec) + interest_level_vec[1]))
    return activity_title, interest_level
end

function data_to_file(filepath::String, activity_vec::Vector{Activity})
    date::Vector{String} = generate_dates(nr_of_samples)
    fell_asleep::Vector{String}, fell_asleep_float::Vector{Float64} = generate_fell_asleep(nr_of_samples)
    woke_up::Vector{String}, woke_up_float::Vector{Float64} = generate_woke_up(nr_of_samples)
    sleep_quality::Vector{String} = generate_sleep_quality(nr_of_samples)
    hours_awake::Vector{String} = generate_hours_awake(nr_of_samples)
    nr_of_sessions::Int64 = abs(round.(Int64, rand(Normal(40, 20))))
    session_indices::Vector{Int64} = sort!(ceil.(Int64, rand(nr_of_sessions)*nr_of_samples))
    interval_start::Vector{Float64} = woke_up_float .+ 1
    fell_asleep_float = ifelse.(fell_asleep_float .< 6.0, fell_asleep_float .+ 24, fell_asleep_float)
    interval_end::Vector{Float64} = fell_asleep_float[2:end] .- 1
    push!(interval_end, 24.0)
    open(filepath, "w") do io
        for i in eachindex(date)
            if !(i in session_indices)
                write(
                    io,
                    date[i] * ";" *
                    fell_asleep[i] * ";" *
                    woke_up[i] * ";" *
                    sleep_quality[i] * ";" *
                    hours_awake[i] * ";00:00;00:00;00:00;;0\n"
                )
            else
                session_starts::String = ""
                session_ends::String = ""
                meal_befores::String = ""
                activities::String = ""
                interest_levels::String = ""
                for j in session_indices
                    if j == i
                        session_start::String, session_end::String, meal_before::String = generate_session_times(interval_start[i], interval_end[i])
                        activity::String, interest_level::String = generate_activity_and_interest_level(activity_vec)
                        session_starts *= session_start * ", "
                        session_ends *= session_end * ", "
                        meal_befores *= meal_before * ", "
                        activities *= activity * ", "
                        interest_levels *= interest_level * ", "
                    end
                end
                # Removing the last comma and space:
                session_starts = session_starts[1:end-2]
                session_ends = session_ends[1:end-2]
                meal_befores = meal_befores[1:end-2]
                activities = activities[1:end-2]
                interest_levels = interest_levels[1:end-2]
                write(
                    io,
                    date[i] * ";" *
                    fell_asleep[i] * ";" *
                    woke_up[i] * ";" *
                    sleep_quality[i] * ";" *
                    hours_awake[i] * ";" *
                    session_starts * ";" * 
                    session_ends * ";" * 
                    meal_befores * ";" *
                    activities * ";" *
                    interest_levels * "\n"
                )
            end
        end
    end
end

data_to_file("tom_session_data.txt", activity_vec)