import sqlight.{type Error as SqlightError}
import gleam/json
import gleam/string_builder.{type StringBuilder}

pub fn sqlight_err(err: SqlightError) -> StringBuilder {
  let res = {
    let object = json.object([#("message", json.string(err.message))])
    Ok(json.to_string_builder(object))
  }

  case res {
    Ok(result) -> result
    Error(err) -> err
  }
}
