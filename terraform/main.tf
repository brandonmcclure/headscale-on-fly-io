resource "fly_app" "headscale" {
  name = var.fly_app_name
}

resource "fly_volume" "persistent" {
  for_each = toset(var.fly_regions)

  name   = "persistent"
  app    = resource.fly_app.headscale.name
  size   = 1
  region = each.key
}
