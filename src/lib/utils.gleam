import ids/nanoid
import gleam/dynamic
import gleam/string_builder.{type StringBuilder}
import gleam/json

pub type UserInput {
  UserInput(username: String, email: String, password: String)
}

pub fn generate_nanoid() -> String {
  let id = nanoid.generate()
  id
}

pub fn decode_input(
  input: dynamic.Dynamic,
  decoder: fn(dynamic.Dynamic) -> Result(a, dynamic.DecodeErrors),
) {
  let assert Ok(user_input) = decoder(input)
  user_input
}

pub fn failed_to_create() -> StringBuilder {
  let u = json.object([#("message", json.string("Failed to create resource"))])
  json.to_string_builder(u)
}

 pub fn failed_to_get(event: String) -> StringBuilder {
  let u = json.object([
		#("message", json.string("Failed to get resource")),
		#("event", json.string(event))
	])
  json.to_string_builder(u)
}
