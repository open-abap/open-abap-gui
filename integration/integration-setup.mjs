import { SQLiteDatabaseClient } from "@abaplint/database-sqlite";

const FIXTURE_SQL = [
  `INSERT INTO "zsflight" ("carrid", "connid", "fldate", "price", "currency", "planetype", "cityfrom", "cityto") VALUES ('AA', '0017', '20260101', 0.00, 'USD', 'BOEING 747', 'New York', 'London');`,
  `INSERT INTO "zsflight" ("carrid", "connid", "fldate", "price", "currency", "planetype", "cityfrom", "cityto") VALUES ('AA', '0018', '20260115', 123.45, 'USD', 'AIRBUS A320', 'Chicago', 'Paris');`,
  `INSERT INTO "zsflight" ("carrid", "connid", "fldate", "price", "currency", "planetype", "cityfrom", "cityto") VALUES ('LH', '0400', '20260228', 999999999.99, 'EUR', 'AIRBUS A350', 'Frankfurt', 'Tokyo');`,
  `INSERT INTO "zsflight" ("carrid", "connid", "fldate", "price", "currency", "planetype", "cityfrom", "cityto") VALUES ('LH', '0401', '20991231', 42.50, 'EUR', 'BOEING 737', 'Munich', 'Rome');`,
  `INSERT INTO "zsflight" ("carrid", "connid", "fldate", "price", "currency", "planetype", "cityfrom", "cityto") VALUES ('SQ', '0020', '20260331', 12.34, 'SGD', 'AIRBUS A380', 'Singapore', 'International Hub');`
];

let database;

async function seed() {
  await database.execute(`DELETE FROM "zsflight";`);
  await database.execute(FIXTURE_SQL);
}

export async function setupDatabase(abap, schemas, insert) {
  database = new SQLiteDatabaseClient();
  abap.context.databaseConnections.DEFAULT = database;
  await database.connect();
  await database.execute(schemas.sqlite);
  await database.execute(insert);
  await seed();
}

export async function resetDatabase() {
  if (database === undefined) {
    throw new Error("ZSFLIGHT database has not been initialized");
  }
  await seed();
}

export async function clearDatabase() {
  if (database === undefined) {
    throw new Error("ZSFLIGHT database has not been initialized");
  }
  await database.execute(`DELETE FROM "zsflight";`);
}

