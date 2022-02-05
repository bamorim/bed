# Type Mappings

This document aims to describe how we would map GraphQL Types into JSON Schema types.

## Introduction

Well, the first thing that is clear right away is that GraphQL types are stricter than JSON Schema. This is because GraphQL aims to always make it clear the final JSON structure in a well defined way.

This means that we cannot have something like `union StringOrObject = String | MyObject` where `MyObject` is an object type.

However, this is perfectly valid in JSON Schema with `anyOf`. Also, in JSON schema we can combine types with `{"type": ["number", "object"]}`.

Also, for the initial version, the JSON Schema will not contain any validation as it will only map what the GraphQL Type defines.

Later on we could add a way to provide extra information.

## Scalar Mappings

| GraphQL Type  | JSON Schema           |
|---------------|-----------------------|
| `Int`         | `{"type": "integer"}` |
| `Number`      | `{"type": "number"}`  |
| `Boolean`     | `{"type": "boolean"}` |
| Other scalars | `{"type": "string"}`  |

## Mapping Objects

**This is a WIP**