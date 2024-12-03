-- Introduce the necessary modules/libraries we need for this plugin 
local core      = require("apisix.core")
local http      = require("resty.http")
local plugin    = require("apisix.plugin")
local cjson     = require("cjson")

-- Declare the plugin's name
local plugin_name = "hospital-schedules"

local default_uri = "/hospital/schedules"

-- Define the plugin schema format
local plugin_schema = {
    type = "object",
}

local attr_schema = {
    type = "object",
    properties = {
        uri = {
            type = "string",
            description = "uri for hospital schedule aggregation",
            default = default_uri
        }
    },
}

-- Define the plugin with its version, priority, name, and schema
local _M = {
    version = 1.0,
    priority = 1000,
    name = plugin_name,
    schema = plugin_schema,
    attr_schema = attr_schema,
    scope = "global"
}

-- Declare the hospitals endpoints
local http_string = "http://"
local GRANDOAK_ENDPOINT = table.concat({http_string, os.getenv("GRANDOAK_ENDPOINT"), "/doctors"})
local PINEVALLEY_ENDPOINT = table.concat({http_string, os.getenv("PINEVALLEY_ENDPOINT"), "/appointments"})
local SPRUCECITY_ENDPOINT = table.concat({http_string, os.getenv("SPRUCECITY_ENDPOINT"), "/schedules"})

-- Function to check if the plugin configuration is correct
function _M.check_schema(conf)
  -- Validate the configuration against the schema
  local ok, err = core.schema.check(plugin_schema, conf)
  -- If validation fails, return false and the error
  if not ok then
      return false, err
  end
  -- If validation succeeds, return true
  return true
end

-- Function to be called during the access phase
local function get_hospitals()
    local httpc = http.new()
    local res_grandoak, err = httpc:request_uri(GRANDOAK_ENDPOINT, {
        method = "GET",
    })

    local res_pinevalley, err = httpc:request_uri(PINEVALLEY_ENDPOINT, {
        method = "GET",
    })

    local res_sprucecity, err = httpc:request_uri(SPRUCECITY_ENDPOINT, {
        method = "GET",
    })

    -- Combine the tables together
    local grandoak_data = cjson.decode(res_grandoak.body)
    local pinevalley_data = cjson.decode(res_pinevalley.body)
    -- local sprucecity_data = xml.from_string(res_sprucecity.body)

    local combined_response = grandoak_data
    combined_response = table.move(pinevalley_data, 1, #pinevalley_data, #combined_response + 1, combined_response)
    core.log.warn(cjson.encode(combined_response))
    -- combined_response = table.move(sprucecity_data, 1, #sprucecity_data, #combined_response + 1, combined_response)

    return 200, combined_response
end

function _M.api()
    local uri = default_uri
    local attr = plugin.plugin_attr(plugin_name)
    if attr then
        uri = attr.uri or default_uri
    end
    return {
        {
            methods = {"GET"},
            uri = uri,
            handler = get_hospitals,
        }
    }
end

-- Return the plugin so it can be used by APISIX
return _M