local typedefs = require "kong.db.schema.typedefs"

return {
  name = "aggregator",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { grand_oak_service_url = typedefs.url { required = true } },
          { pine_valley_service_url = typedefs.url { required = true } },
          { spruce_city_service_url = typedefs.url { required = true } },
        },
      },
    },
  },
}
