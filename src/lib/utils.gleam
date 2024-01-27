import ids/nanoid

pub fn generate_nanoid() -> String {
  let id = nanoid.generate()
  id
}
