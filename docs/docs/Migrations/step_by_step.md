---

title: Schema migration helpers
description: Use generated code reflecting over all schema versions to write migrations step-by-step.

---



Database migrations are typically written incrementally, with one piece of code transforming
the database schema to the next version. By chaining these migrations, you can write
schema migrations even for very old app versions.

Reliably writing migrations between app versions isn't easy though. This code needs to be
maintained and tested, but the growing complexity of the database schema shouldn't make
migrations more complex.
Let's take a look at a typical example making the incremental migrations pattern hard:

1. In the initial database schema, we have a bunch of tables.
2. In the migration from 1 to 2, we add a column `birthDate` to one of the table (`Users`).
3. In version 3, we realize that we actually don't want to store users at all and delete
   the table.

Before version 3, the only migration could have been written as `m.addColumn(users, users.birthDate)`.
But now that the `Users` table doesn't exist in the source code anymore, that's no longer possible!
Sure, we could remember that the migration from 1 to 2 is now pointless and just skip it if a user
upgrades from 1 to 3 directly, but this adds a lot of complexity. For more complex migration scripts
spanning many versions, this can quickly lead to code that's hard to understand and maintain.

## Generating step-by-step code

Drift provides tools to [export old schema versions](exports.md). After exporting all
your schema versions, you can use the following command to generate code aiding with the implementation
of step-by-step migrations:

```
$ dart run drift_dev schema steps drift_schemas/ lib/database/schema_versions.dart
```

The first argument (`drift_schemas/`) is the folder storing exported schemas, the second argument is
the path of the file to generate. Typically, you'd generate a file next to your database class.

The generated file contains a `stepByStep` method which can be used to write migrations easily:

{{ load_snippet('stepbystep','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

`stepByStep` expects a callback for each schema upgrade responsible for running the partial migration.
That callback receives two parameters: A migrator `m` (similar to the regular migrator you'd get for
`onUpgrade` callbacks) and a `schema` parameter that gives you access to the schema at the version you're
migrating to.
For instance, in the `from1To2` function, `schema` provides getters for the database schema at version 2.
The migrator passed to the function is also set up to consider that specific version by default.
A call to `m.recreateAllViews()` would re-create views at the expected state of schema version 2, for instance.

## Customizing step-by-step migrations

The `stepByStep` function generated by the `drift_dev schema steps` command gives you an
`OnUpgrade` callback.
But you might want to customize the upgrade behavior, for instance by adding foreign key
checks afterwards (as described in [tips](index.md#tips)).

The `Migrator.runMigrationSteps` helper method can be used for that, as this example
shows:

{{ load_snippet('stepbystep2','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

Here, foreign keys are disabled before runnign the migration and re-enabled afterwards.
A check ensuring no inconsistencies occurred helps catching issues with the migration
in debug modes.

## Moving to step-by-step migrations

If you've been using drift before `stepByStep` was added to the library, or if you've never exported a schema,
you can move to step-by-step migrations by pinning the `from` value in `Migrator.runMigrationSteps` to a known
starting point.

This allows you to perform all prior migration work to get the database to the "starting" point for
`stepByStep` migrations, and then use `stepByStep` migrations beyond that schema version.

{{ load_snippet('stepbystep3','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

Here, we give a "floor" to the `from` value of `2`, since we've performed all other migration work to get to
this point. From now on, you can generate step-by-step migrations for each schema change.

If you did not do this, a user migrating from schema 1 directly to schema 3 would not properly walk migrations
and apply all migration changes required.