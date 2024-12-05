local http       = require "resty.http"
local cjson      = require "cjson"

local Aggregator = {
    PRIORITY = 10,
    VERSION = "1.0.0",
}

local function format_time(hour, minute)
    local period = "AM"
    hour = tonumber(hour)

    if hour >= 12 then
        period = "PM"
        if hour > 12 then
            hour = hour - 12
        end
    elseif hour == 0 then
        hour = 12
    end

    return string.format("%02d:%02d %s", hour, tonumber(minute), period)
end

--  Function to convert XML to table
local function xml_to_table(xml_string)
    local result = { doctors = {} }

    for doctor_element in xml_string:gmatch("<doctor>(.-)</doctor>") do
        local doctor = {}

        -- Extract first name and last name
        for field, value in doctor_element:gmatch("<(%w+[_%w]*)>(.-)</%1>") do
            -- Debugging output to check what is being matched

            if field == "first_name" then
                doctor.first_name = value
            elseif field == "last_name" then
                doctor.last_name = value
            elseif field == "gender" then
                doctor.gender = value == "true" and "Male" or "Female"
            elseif field == "id" then
                doctor.id = tonumber(value)
            elseif field == "phone" then
                doctor.phone = value
            elseif field == "email" then
                doctor.email = value
            elseif field == "specialty" then
                doctor.specialty = value
            end
        end

        -- Extract schedule
        doctor.schedule = {}
        for schedule_detail in doctor_element:gmatch("<schedule>(.-)</schedule>") do
            local day = schedule_detail:match("<day>(.-)</day>")
            local start_hour = schedule_detail:match("<start_time><hour>(.-)</hour><minute>(.-)</minute></start_time>")
            local end_hour = schedule_detail:match("<end_time><hour>(.-)</hour><minute>(.-)</minute></end_time>")

            if day and start_hour and end_hour then
                local start_time = format_time(start_hour,
                    schedule_detail:match("<start_time><hour>.-</hour><minute>(.-)</minute></start_time>"))
                local end_time = format_time(end_hour,
                    schedule_detail:match("<end_time><hour>.-</hour><minute>(.-)</minute></end_time>"))

                -- Create the schedule entry
                local schedule_entry = {
                    day = day,
                    start_time = start_time,
                    end_time = end_time
                }
                table.insert(doctor.schedule, schedule_entry)
            end
        end

        -- Add the doctor to the result
        table.insert(result.doctors, doctor)
    end

    return result
end

function Aggregator:access(conf)
    local httpc = http.new()

    local res_grandoak, err = httpc:request_uri(conf.grand_oak_service_url, {
        method = "GET",
    })

    local res_pinevalley, err = httpc:request_uri(conf.pine_valley_service_url, {
        method = "GET",
    })

    local res_sprucecity, err = httpc:request_uri(conf.spruce_city_service_url, {
        method = "GET",
    })

    -- Combine the tables together
    local grandoak_data = cjson.decode(res_grandoak.body)
    local pinevalley_data = cjson.decode(res_pinevalley.body)
    local sprucecity_data = xml_to_table(res_sprucecity.body)

    local combined_response = grandoak_data
    combined_response = table.move(pinevalley_data, 1, #pinevalley_data, #combined_response + 1, combined_response)

    if sprucecity_data and sprucecity_data.doctors then
        for _, doctor in ipairs(sprucecity_data.doctors) do
            table.insert(combined_response, doctor)
        end
    end

    kong.response.exit(200, combined_response)
end

return Aggregator
