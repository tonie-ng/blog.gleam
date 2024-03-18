import ids/nanoid
import gleam/string_builder.{type StringBuilder}
import gleam/json

pub type UserInput {
  UserInput(username: String, email: String, password: String)
}

pub fn generate_nanoid() -> String {
  let id = nanoid.generate()
  id
}

pub fn failed_to_create(event: String) -> StringBuilder {
  let u =
    json.object([
      #("message", json.string("Failed to create resource")),
      #("event", json.string(event)),
    ])
  json.to_string_builder(u)
}

pub fn not_authorized(event: String) -> StringBuilder {
  let u =
    json.object([
      #("message", json.string("Unauthorized request")),
      #("event", json.string(event)),
    ])
  json.to_string_builder(u)
}

pub fn failed_to_get(event: String) -> StringBuilder {
  let u =
    json.object([
      #("message", json.string("Failed to get resource")),
      #("event", json.string(event)),
    ])
  json.to_string_builder(u)
}
