pub type User {
  User(
    id: String,
    username: String,
    email: String,
    password: String,
    created_at: Int,
    updated_at: Int,
  )
}

pub type SignUp {
  SignUp(username: String, email: String, password: String)
}
