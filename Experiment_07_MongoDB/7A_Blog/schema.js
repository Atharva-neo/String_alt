// 7A Blog - Task 1 (part 1): create database blogDB and the posts collection with $jsonSchema validation (MongoDB 7)
// Run:  mongosh --quiet --file schema.js
db = db.getSiblingDB("blogDB");                       // "use blogDB" is only valid in the interactive shell, not in script files
function task(n, t) { print("\n### Task " + n + " - " + t); }

task(1, "Create database blogDB and collection posts (validated)");
db.posts.drop();                                       // makes the script re-runnable
db.createCollection("posts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["title", "author", "tags", "likes", "date", "comments"],
      properties: {
        title:    { bsonType: "string", description: "post title" },
        author:   { bsonType: "string" },
        tags:     { bsonType: "array", items: { bsonType: "string" } },
        likes:    { bsonType: "int", minimum: 0 },
        date:     { bsonType: "date" },
        comments: {
          bsonType: "array",                           // embedded documents: comments live INSIDE the post
          items: {
            bsonType: "object",
            required: ["user", "text", "likes"],
            properties: { user: { bsonType: "string" }, text: { bsonType: "string" }, likes: { bsonType: "int", minimum: 0 } }
          }
        }
      }
    }
  }
});
print("collections in blogDB:", db.getCollectionNames());

task(1, "Negative test: a post without the required field 'author' is rejected");
try {
  db.posts.insertOne({ title: "No author", tags: [], likes: 0, date: new Date(), comments: [] });
} catch (e) {
  print("Error code " + e.code + ": " + e.message);
}
