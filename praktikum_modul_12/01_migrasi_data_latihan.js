db = db.getSiblingDB('transport_db');

db.routes.drop();
db.trips.drop();

printjson(db.routes.insertMany([
  { route_id: 12, route_name: "Koridor Pusat–Terminal" },
  { route_id: 15, route_name: "Koridor Kampus–Stasiun" },
  { route_id: 18, route_name: "Koridor Pasar–Kota" }
]));

printjson(db.trips.insertMany([
  { trip_id: "T001", route_id: 12, started_at: "2026-11-02 07:10", status: "completed" },
  { trip_id: "T002", route_id: 15, started_at: "2026-11-02 07:25", status: "completed" },
  { trip_id: "T003", route_id: 12, started_at: "2026-11-03 08:05", status: "delayed" },
  { trip_id: "T004", route_id: 18, started_at: "2026-10-29 06:50", status: "completed" },
  { trip_id: "T005", route_id: 12, started_at: "2026-11-05 17:20", status: "completed" },
  { trip_id: "T006", route_id: 15, started_at: "2026-11-06 09:15", status: "cancelled" }
]));

print('=== Perjalanan rute 12 sejak 2026-11-01 ===');
printjson(db.trips.aggregate([
  { $match: { route_id: 12, started_at: { $gte: "2026-11-01" } } },
  { $lookup: { from: "routes", localField: "route_id", foreignField: "route_id", as: "rute" } },
  { $unwind: "$rute" },
  { $project: { _id: 0, trip_id: 1, started_at: 1, route_name: "$rute.route_name" } }
]).toArray());
