# Expected output - Experiment_07_MongoDB / 7A_Blog

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create database blogDB and collection posts (validated)
collections in blogDB: [ 'posts' ]

### Task 1 - Negative test: a post without the required field 'author' is rejected
Error code 121: Document failed validation
```

## `insert_data.js`

```text
### Task 1 - insertMany into posts and show them with find().pretty()
inserted: 5 documents
{
  _id: 1,
  title: 'Intro to MongoDB',
  author: 'Riya',
  tags: [ 'mongodb', 'nosql' ],
  likes: 25,
  date: ISODate('2026-09-01T00:00:00.000Z'),
  comments: [
    { user: 'Amit', text: 'Very helpful', likes: 3 },
    { user: 'Sneha', text: 'Nice examples', likes: 1 }
  ]
}
{
  _id: 2,
  title: 'Python Tips',
  author: 'Amit',
  tags: [ 'python' ],
  likes: 40,
  date: ISODate('2026-09-10T00:00:00.000Z'),
  comments: [ { user: 'Riya', text: 'Great', likes: 2 } ]
}
{
  _id: 3,
  title: 'Indexes Explained',
  author: 'Riya',
  tags: [ 'mongodb', 'performance' ],
  likes: 12,
  date: ISODate('2026-10-02T00:00:00.000Z'),
  comments: []
}
{
  _id: 4,
  title: 'Aggregation Pipeline Guide',
  author: 'Sneha',
  tags: [ 'mongodb', 'aggregation' ],
  likes: 8,
  date: ISODate('2026-10-15T00:00:00.000Z'),
  comments: []
}
{
  _id: 5,
  title: 'Schema Design Patterns',
  author: 'Amit',
  tags: [ 'nosql', 'design' ],
  likes: 30,
  date: ISODate('2026-09-20T00:00:00.000Z'),
  comments: [ { user: 'Riya', text: 'Useful patterns', likes: 4 } ]
}
countDocuments: 5
```

## `queries.js`

```text
### Task 2 - Posts by Riya with likes > 20, only title and likes
{ title: 'Intro to MongoDB', likes: 25 }

### Task 3 - Posts tagged 'mongodb', newest first
{ _id: 4, title: 'Aggregation Pipeline Guide', date: ISODate('2026-10-15T00:00:00.000Z') }
{ _id: 3, title: 'Indexes Explained', date: ISODate('2026-10-02T00:00:00.000Z') }
{ _id: 1, title: 'Intro to MongoDB', date: ISODate('2026-09-01T00:00:00.000Z') }

### Task 4 - Posts published in September 2026 (date range)
{ _id: 1, title: 'Intro to MongoDB', date: ISODate('2026-09-01T00:00:00.000Z') }
{ _id: 2, title: 'Python Tips', date: ISODate('2026-09-10T00:00:00.000Z') }
{ _id: 5, title: 'Schema Design Patterns', date: ISODate('2026-09-20T00:00:00.000Z') }

### Task 5 - Posts where ANY comment has likes >= 3 ($elemMatch)
{
  _id: 1,
  title: 'Intro to MongoDB',
  comments: [ { user: 'Amit', likes: 3 }, { user: 'Sneha', likes: 1 } ]
}
{ _id: 5, title: 'Schema Design Patterns', comments: [ { user: 'Riya', likes: 4 } ] }
-- why $elemMatch? With { 'comments.likes': {$gte:3}, 'comments.user': 'Sneha' } the two conditions may be satisfied by DIFFERENT comments:
   without $elemMatch : 1
   with    $elemMatch : 0
```

## `crud.js`

```text
### Task 6 - $push a comment to post 3; $pull Amit's comment from post 1
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{
  _id: 1,
  title: 'Intro to MongoDB',
  comments: [ { user: 'Sneha', text: 'Nice examples', likes: 1 } ]
}
{
  _id: 3,
  title: 'Indexes Explained',
  comments: [ { user: 'Neha', text: 'Great explanation', likes: 0 } ]
}

### Task 7 - $inc likes of post 2 by 5
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ _id: 2, title: 'Python Tips', likes: 45 }

### Task 8 - $addToSet tag 'database' to all mongodb posts (no duplicates)
{
  acknowledged: true,
  matchedCount: 3,
  modifiedCount: 3,
  upsertedCount: 0,
  upsertedId: null
}
-- run it a second time: modifiedCount must be 0 because the element is already in each set
{
  acknowledged: true,
  matchedCount: 3,
  modifiedCount: 0,
  upsertedCount: 0,
  upsertedId: null
}
{ _id: 1, title: 'Intro to MongoDB', tags: [ 'mongodb', 'nosql', 'database' ] }
{ _id: 3, title: 'Indexes Explained', tags: [ 'mongodb', 'performance', 'database' ] }
{
  _id: 4,
  title: 'Aggregation Pipeline Guide',
  tags: [ 'mongodb', 'aggregation', 'database' ]
}

### Task 12 - Delete posts with zero comments AND likes < 15
candidates: [{"_id":4,"title":"Aggregation Pipeline Guide"}]
{ acknowledged: true, deletedCount: 1 }
remaining posts: 4 [{"_id":1,"title":"Intro to MongoDB"},{"_id":2,"title":"Python Tips"},{"_id":3,"title":"Indexes Explained"},{"_id":5,"title":"Schema Design Patterns"}]

### Task extra - Negative tests: duplicate _id and invalid document
Duplicate _id -> code 11000: E11000 duplicate key error collection: blogDB.posts index: _id_ dup key: { _id: 1 }
Validation -> code 121: Document failed validation
{
  acknowledged: true,
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 0,
  upsertedId: null
}
(matchedCount 0: updating a missing document is not an error)
```

## `aggregation.js`

```text
### Task 9 - Count posts per tag ($unwind + $group)
{ _id: 'database', posts: 2 }
{ _id: 'mongodb', posts: 2 }
{ _id: 'nosql', posts: 2 }
{ _id: 'design', posts: 1 }
{ _id: 'performance', posts: 1 }
{ _id: 'python', posts: 1 }

### Task 10 - Post(s) with the most comments ($size inside $project)
{
  _id: 1,
  titles: [ 'Intro to MongoDB', 'Python Tips', 'Indexes Explained', 'Schema Design Patterns' ]
}
-- all posts with their comment counts:
{ title: 'Indexes Explained', comment_count: 1 }
{ title: 'Intro to MongoDB', comment_count: 1 }
{ title: 'Python Tips', comment_count: 1 }
{ title: 'Schema Design Patterns', comment_count: 1 }

### Task 11 - Author-wise total likes, highest first
{ _id: 'Amit', total_likes: 75, posts: 2 }
{ _id: 'Riya', total_likes: 37, posts: 2 }

### Task extra - Average likes per tag and most active commenter
{ _id: 'database', avg_likes: 18.5 }
{ _id: 'design', avg_likes: 30 }
{ _id: 'mongodb', avg_likes: 18.5 }
{ _id: 'nosql', avg_likes: 27.5 }
{ _id: 'performance', avg_likes: 12 }
{ _id: 'python', avg_likes: 45 }
{ _id: 'Riya', comments: 2 }
{ _id: 'Neha', comments: 1 }
{ _id: 'Sneha', comments: 1 }
```

## `indexes.js`

```text
### Task idx-1 - Query without an index: explain('executionStats')
{ stage: 'COLLSCAN', nReturned: 2, totalKeysExamined: 0, totalDocsExamined: 4 }

### Task idx-2 - Single-field index on author, then the same query again
created: author_1
{ stage: 'IXSCAN', nReturned: 2, totalKeysExamined: 2, totalDocsExamined: 2 }

### Task idx-3 - Compound index {author: 1, date: -1} (equality field first, then the sort/range field)
created: author_1_date_-1
{ v: 2, key: { _id: 1 }, name: '_id_' }
{ v: 2, key: { author: 1 }, name: 'author_1' }
{ v: 2, key: { author: 1, date: -1 }, name: 'author_1_date_-1' }

### Task idx-4 - Text index on title and a text search
created: title_text
{ _id: 3, title: 'Indexes Explained' }

### Task idx-5 - Unique index demonstration (title must be unique) and cleanup
created: uq_title
Duplicate title -> code 11000: E11000 duplicate key error collection: blogDB.posts index: uq_title dup key: { title: 'Python Tips' }
indexes now: _id_, author_1, author_1_date_-1, title_text
```
