# Expected output - Experiment_07_MongoDB / 7C_Movie_Catalogue

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create collection movies (validated)
collections: [ 'movies' ]

### Task 1 - Negative test: rating 11 is rejected
code 121: Document failed validation
```

## `insert_data.js`

```text
### Task 1 - Insert the movies
count: 3
{
  _id: ObjectId('6540a1b2c3d4000000000002'),
  title: 'Space Journey',
  year: 2019,
  genre: [ 'Sci-Fi', 'Drama' ],
  rating: 8.1
}
{
  _id: ObjectId('6540a1b2c3d4000000000003'),
  title: 'City Lights',
  year: 2021,
  genre: [ 'Drama' ],
  rating: 7.4
}
{
  _id: ObjectId('6540a1b2c3d4000000000004'),
  title: 'Deep Ocean',
  year: 2023,
  genre: [ 'Sci-Fi', 'Thriller' ],
  rating: 6.9
}
```

## `queries.js`

```text
### Task 2 - Sci-Fi movies released after 2020
{ title: 'Deep Ocean', year: 2023, genre: [ 'Sci-Fi', 'Thriller' ] }

### Task 3 - Movies with rating between 7 and 8.5 - title and rating only
{ title: 'Space Journey', rating: 8.1 }
{ title: 'City Lights', rating: 7.4 }

### Task 4 - Movies in which Actor A acted (dot notation on cast.name)
{ title: 'Space Journey' }
{ title: 'Deep Ocean' }

### Task 5 - Movies that belong to exactly two genres ($size)
{ title: 'Space Journey', genre: [ 'Sci-Fi', 'Drama' ] }
{ title: 'Deep Ocean', genre: [ 'Sci-Fi', 'Thriller' ] }
```

## `aggregation.js`

```text
### Task 6 - Each actor with the number of films ($unwind cast, $group)
{ _id: 'Actor A', films: 2, titles: [ 'Space Journey', 'Deep Ocean' ] }
{ _id: 'Actor B', films: 2, titles: [ 'Space Journey', 'City Lights' ] }
{ _id: 'Actor C', films: 1, titles: [ 'City Lights' ] }

### Task 7 - Average rating per genre ($unwind genre)
{ _id: 'Drama', avg_rating: 7.75, movies: 2 }
{ _id: 'Sci-Fi', avg_rating: 7.5, movies: 2 }
{ _id: 'Thriller', avg_rating: 6.9, movies: 1 }

### Task 8 - Highest rated movie of each year ($sort then $group with $first)
{ _id: 2019, title: 'Space Journey', rating: 8.1 }
{ _id: 2021, title: 'City Lights', rating: 7.4 }
{ _id: 2023, title: 'Deep Ocean', rating: 6.9 }
```

## `indexes.js`

```text
### Task 9 - Create a text index on title and plot
created: title_text_plot_text

### Task 9 - Search for 'city' ($text, sorted by title for a stable output)
{ title: 'City Lights' }
{ title: 'Deep Ocean' }
-- negation and phrase search: 'city -ocean' and "big city"
{ title: 'City Lights' }
{ title: 'City Lights' }
_id_
title_text_plot_text
```

## `crud.js`

```text
### Task 10 - Add genre 'Adventure' to Space Journey with $addToSet
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ title: 'Space Journey', genre: [ 'Sci-Fi', 'Drama', 'Adventure' ] }

### Task 11 - Increase the rating of all 2019 movies by 0.2
naive 8.1 + 0.2 = 8.299999999999999
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ title: 'Space Journey', rating: 8.3 }

### Task 12 - Remove Actor B from City Lights ($pull) and delete movies with rating < 7
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0,
  upsertedId: null
}
{ title: 'City Lights', cast: [ { name: 'Actor C', role: 'Friend' } ] }
{ acknowledged: true, deletedCount: 1 }
{ title: 'City Lights', rating: 7.4 }
{ title: 'Space Journey', rating: 8.3 }
```
