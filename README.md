# Bed

This is an experiment to make it easy to publish a REST API on top of an
existing GraphQL API with Open API Spec auto-documentation.

## The Problem

Recently at my company, we received a mandate that all APIs on our core platform
need to be exposed as a REST API with Open API Spec docs. Our team was
experimenting with Absinthe and GraphQL before and we loved the tooling. Going
back to writing REST APIs was not something we were looking forward (mostly
because the developer experience of GraphQL was amazing).

We wanted to be able to continue exploring GraphQL while being able to comply
with the company-wide rules, but this meant we needed to maintain two different
APIs if we wanted to do that.

This sparked this idea, which took inspiration from the [GRPC
Gateway](https://grpc-ecosystem.github.io/grpc-gateway/) project, but for
GraphQL instead.

## Existing Solutions

The only tool I've found that was trying something similar was
[Sofa](https://www.sofa-api.com/), from the folks at The Guild. However, I
didn't liked the approach because we didn't had much control over as the tool
tried to generate http endpoints automatically, which meant the result of your
HTTP API was directly impacted by your current GraphQL implementation.

## Proposed Solution Goal

I wanted to be able to customize the REST endpoints and to build that on top of
the existing GraphQL servers. So the goal of this tool is to not only receive a
GraphQL Schema, but also a few queries. Basically, each query/mutation would be
translated to one REST endpoint.

Also, I realised we could use custom directives to represent all the
translations in GraphQL language.

So for example, a simple TODO List API could look something like this:

```graphql
query ListTodos($limit: Int = 100, $offset: Int = 0) 
@endpoint(method: "GET", path: "/todos")
@responseMap(body: "{data: body.todos, total: body.todoCount}", status: 200)
@bodyFilter(key: "snake_case") {
  todos(limit: $limit, offset: $offset) {
    title
    done: completedAt @transform(value: "not(is_null(data))")
    tagNames: tags @transform(value: "map(data, .name)") {
      name
    }
  }
  todoCount
}
```

That would mean a `GET /todos?limit=50&offset=50` could return something like:

```json
{
  "data": [
    {
      "title": "Take out trash",
      "done": false,
      "tag_names": ["home", "personal"]
    },
    {
      "title": "Submit CV",
      "done": true,
      "tag_names": ["home", "work"]
    }
  ],
  "total": 52
}
```
 
The expression language on the `@responseMap` and `@transform` directives is
still not decided, but I wanted something like
[jq](https://stedolan.github.io/jq/) or
[Rego](https://www.openpolicyagent.org/docs/latest/policy-language/). It should
at least:
- Be able to get nested JSON values
- Map over lists
- Build objects and arrays
- Some built-in functions like `is_null`, `length`, etc.

Another idea is to use a more complete programming language like
[Lua](https://www.lua.org/) and [Luerl](https://github.com/rvirding/luerl)

I also need to be able to parse the query to understand the impact on the
resulting JSON schema.

## The Plan

This is, in general lines, how I plan to accomplish that:

- [x] Get information about a schema (currently by parsing the introspection
  query result by calling `Absinthe.Schema.introspect/1`).
  - [ ] Maybe we can add tests (maybe property testing?) that we can reconstruct the introspection schema to make sure we are not loosing any valuable information.
- [ ] Build a JSON schema from a query (no transforms)
- [ ] Implement the runtime of the proxy by using `@endpoint` directives and
  macros to create a plug (always returning 200).
- [ ] Generate OAS JSON
- [ ] Map query params query variables (and update OAS support)
- [ ] Implement `@responseMap` (and update JSON Schema and OAS support)
- [ ] Implement `@transform` (and update JSON Schema and OAS support)