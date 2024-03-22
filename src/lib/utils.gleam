import ids/nanoid
import lib/types
import gleam/string_builder.{type StringBuilder}
import gleam/json.{type Json}
import gleam/dynamic
import gleam/list

pub fn decode_update(
  json: dynamic.Dynamic,
) -> Result(types.Update, dynamic.DecodeErrors) {
  let decoder = {
    dynamic.decode2(
      types.Update,
      dynamic.field(named: "field", of: dynamic.string),
      dynamic.field(named: "value", of: dynamic.string),
    )
  }
  decoder(json)
}

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

pub type ToJson {
  ToJsonUser(List(types.User))
  ToJsonArticle(List(types.Article))
}

pub fn list_to_json(l: ToJson) -> Json {
  case l {
    ToJsonUser(u) -> {
      let lu =
        list.map(u, fn(user) {
          let a =
            json.object([
              #("id", json.string(user.id)),
              #("username", json.string(user.username)),
              #("title", json.string(user.email)),
              #("created_at", json.string(user.created_at)),
              #("update_at", json.string(user.updated_at)),
            ])
          a
        })
      json.preprocessed_array(lu)
    }
    ToJsonArticle(a) -> {
      let la =
        list.map(a, fn(article) {
          let a =
            json.object([
              #("id", json.string(article.id)),
              #("user_id", json.string(article.user_id)),
              #("title", json.string(article.title)),
              #("body", json.string(article.body)),
              #("created_at", json.string(article.created_at)),
              #("update_at", json.string(article.updated_at)),
            ])
          a
        })
      json.preprocessed_array(la)
    }
  }
}
