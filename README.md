# TypeDBClient_2.jl

[![Build Status](https://github.com/FrankUrbach/TypeDBClient_2.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/FrankUrbach/TypeDBClient_2.jl/actions)
[![v0.0.1](https://img.shields.io/github/v/release/FrankUrbach/TypeDBClient_2.jl)](https://github.com/FrankUrbach/TypeDBClient_2.jl/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Julia FFI client for [TypeDB 3.x](https://typedb.com), wrapping the official
C driver (`libtypedb_driver_clib`) via Julia's `ccall` interface.

This package is the successor to
[TypeDBClient.jl](https://github.com/Humans-of-Julia/TypeDBClient.jl), which
targeted TypeDB 2.x. TypeDB 3.x introduced breaking changes to the protocol
(sessions were removed, the query answer model was redesigned) that required a
ground-up rewrite.

## What is TypeDB?

> TypeDB is a strongly typed database with a rich type system. TypeDB allows
> you to model your domain based on logical and object-oriented principles.
> Querying is performed with [TypeQL](https://typedb.com/docs/typeql/overview),
> TypeDB's own query language.

Read more at [typedb.com](https://typedb.com).

## TypeDB 3.x – What changed from 2.x?

The key architectural changes in TypeDB 3.x relevant to this client:

- **No more Sessions** – transactions are opened directly on the driver with
  a database name, transaction type, and options. The session layer from 2.x
  is gone.
- **New query answer model** – `query()` returns a `QueryAnswer` that is
  either a stream of `ConceptRow`s (match/insert/delete/update queries), a
  stream of JSON documents (fetch queries), or an ok-signal
  (schema/write-without-result queries).
- **C FFI driver** – TypeDB now ships an official C shared library
  (`libtypedb_driver_clib`) that all language drivers wrap. This Julia client
  uses it directly via `ccall`.

## Requirements

- Julia **1.6** or later
- **TypeDB 3.x** server running and accessible
- The native library `libtypedb_driver_clib` (`.dylib` / `.so` / `.dll`)

The native library can be obtained in one of two ways:

1. **Pre-built binary** – download from the
   [typedb-driver releases](https://github.com/typedb/typedb-driver/releases)
   page.
2. **Build from source** – requires Rust + Cargo:
   ```bash
   git clone https://github.com/typedb/typedb-driver.git
   cd typedb-driver && cargo build --release -p typedb_driver_clib
   ```

> **Coming soon:** Once the Yggdrasil PR for `TypeDBDriverClib_jll` is merged,
> the native library will be installed automatically via Julia's package manager
> – no manual steps needed.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/FrankUrbach/TypeDBClient_2.jl")
```

After installing, register the native library once:

```bash
# Option A – point to a pre-built library
export TYPEDB_DRIVER_LIB=/path/to/libtypedb_driver_clib.dylib

# Option B – point to the typedb-driver source (builds via cargo)
export TYPEDB_DRIVER_SRC=/path/to/typedb-driver

julia -e 'using Pkg; Pkg.build("TypeDBClient")'
```

## Quick Start

```julia
using TypeDBClient

# Open a connection to a TypeDB 3.x server
driver = TypeDBDriver("localhost:1729")

# Database management
create_database(driver, "my_db")
println(list_databases(driver))   # ["my_db"]

# Define a schema
transaction(driver, "my_db", TransactionType.SCHEMA) do tx
    query(tx, "define entity person, owns name; attribute name, value string;")
end

# Insert data
transaction(driver, "my_db", TransactionType.WRITE) do tx
    query(tx, """insert \$p isa person, has name "Alice";""")
end

# Query data
transaction(driver, "my_db", TransactionType.READ) do tx
    answer = query(tx, "match \$p isa person, has name \$n; select \$n;")
    for row in rows(answer)
        println(get(row, "n"))
    end
end

# Clean up
delete_database(driver, "my_db")
close(driver)
```

## API Overview

### Driver

| Function | Description |
|---|---|
| `TypeDBDriver(address)` | Connect to a TypeDB server |
| `TypeDBDriver(address, credentials)` | Connect with username/password |
| `close(driver)` | Close the connection |

### Database Management

| Function | Description |
|---|---|
| `list_databases(driver)` | List all database names |
| `contains_database(driver, name)` | Check if a database exists |
| `create_database(driver, name)` | Create a new database |
| `get_database(driver, name)` | Get a `Database` handle |
| `delete_database(driver, name)` | Delete a database |
| `get_schema(db)` | Return the TypeQL schema as a string |

### Transactions

```julia
# Automatic commit on success, rollback on error:
transaction(driver, "db_name", TransactionType.WRITE) do tx
    query(tx, "insert ...")
end

# Also works with a Database handle:
db = get_database(driver, "db_name")
transaction(db, TransactionType.READ) do tx
    ...
end
```

Transaction types: `TransactionType.READ`, `TransactionType.WRITE`,
`TransactionType.SCHEMA`.

### Queries

```julia
answer = query(tx, "match \$x isa thing; select \$x;")

# Row queries (match / insert / delete / update / select)
for row in rows(answer)
    concept = get(row, "x")
end

# Fetch / document queries
for doc in documents(answer)
    println(doc)   # JSON string
end

# Write / schema queries
is_ok(answer)   # returns true on success
```

## Running the Tests

**Unit tests** (no server required):

```bash
julia --project -e 'using Pkg; Pkg.test("TypeDBClient")'
```

**Integration tests** (TypeDB 3.x server must be running):

```bash
TYPEDB_TEST_ADDRESS=localhost:1729 julia --project -e 'using Pkg; Pkg.test("TypeDBClient")'
```

## Project Status

This package is in early development (`v0.0.1`). The core functionality –
connecting to TypeDB, managing databases, running transactions, and processing
query answers – is implemented and tested.

**Roadmap:**

- [ ] Automatic binary installation via `TypeDBDriverClib_jll`
      (pending Yggdrasil PR [#13229](https://github.com/JuliaPackaging/Yggdrasil/pull/13229))
- [ ] Registration in the Julia General Registry (`Pkg.add("TypeDBClient")`)
- [ ] Full concept API (attribute values, type hierarchy traversal)
- [ ] Async query streaming
- [ ] Documentation (Documenter.jl)

## Contributing

Contributions and feedback are welcome. Please open an issue or pull request
on [GitHub](https://github.com/FrankUrbach/TypeDBClient_2.jl).

For questions about TypeDB itself, visit the
[TypeDB Discord](https://typedb.com/discord) or
[TypeDB Forum](https://forum.typedb.com).

## License

This package is licensed under the [MIT License](LICENSE).
