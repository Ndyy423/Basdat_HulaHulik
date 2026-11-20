db = db.getSiblingDB('transport_db');

print('=== Trip rute 12 sejak 2026-11-01 ===');
printjson(db.trips.aggregate([
  { $match: { route_id: 12, started_at: { $gte: '2026-11-01' } } },
  { $lookup: { from: 'routes', localField: 'route_id', foreignField: 'route_id', as: 'rute' } },
  { $unwind: '$rute' },
  { $project: { _id: 0, trip_id: 1, started_at: 1, route_name: '$rute.route_name' } }
]).toArray());

// 02_query_transportasi.js  (bagian 2: execution plan)
const Q = { route_id: 12, started_at: { $gte: '2026-11-01' } };
try { db.trips.dropIndex('idx_route_started'); } catch (e) {}   // supaya bisa diulang

print('=== SEBELUM INDEX ===');
let e1 = db.trips.find(Q).explain('executionStats');
printjson(e1.queryPlanner.winningPlan);
printjson({
  nReturned: e1.executionStats.nReturned,
  totalKeysExamined: e1.executionStats.totalKeysExamined,
  totalDocsExamined: e1.executionStats.totalDocsExamined,
  executionTimeMillis: e1.executionStats.executionTimeMillis
});

db.trips.createIndex({ route_id: 1, started_at: 1 }, { name: 'idx_route_started' });

print('=== SESUDAH INDEX ===');
let e2 = db.trips.find(Q).explain('executionStats');
printjson(e2.queryPlanner.winningPlan);
printjson({
  nReturned: e2.executionStats.nReturned,
  totalKeysExamined: e2.executionStats.totalKeysExamined,
  totalDocsExamined: e2.executionStats.totalDocsExamined,
  executionTimeMillis: e2.executionStats.executionTimeMillis
});
