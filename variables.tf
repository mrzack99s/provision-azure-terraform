variable "provide_objects" {
  type = list(object({
    role         = string
    location     = string
    subnets = object({
      hub = object({
        main_subnet = string
        subnet      = string
      })
      spoke = object({
        main_subnet = string
        subnet      = string
        amountVMs   = number

      })
    })
  }))
  default = [
    {
      role         = "primary"
      location     = "Southeast Asia"
      subnets = {
        hub = {
          main_subnet = "10.10.0.0/16"
          subnet      = "10.10.0.0/24"

        }
        spoke = {
          main_subnet = "10.11.0.0/16"
          subnet      = "10.11.0.0/24"
          amountVMs   = 2

        }
      }
    },
    {
      role     = "secondary"
      location = "East Asia"
      subnets = {
        hub = {
          main_subnet = "10.12.0.0/16"
          subnet      = "10.12.0.0/24"

        }
        spoke = {
          main_subnet = "10.13.0.0/16"
          subnet      = "10.13.0.0/24"
          amountVMs   = 2

        }
      }
    }
  ]
}
