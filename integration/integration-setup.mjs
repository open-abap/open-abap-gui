import { SQLiteDatabaseClient } from "@abaplint/database-sqlite";

export async function setupDatabase(abap, schemas, insert) {
  const database = new SQLiteDatabaseClient();
  abap.context.databaseConnections.DEFAULT = database;
  await database.connect();
  await database.execute(schemas.sqlite);
  await database.execute(insert);
}
